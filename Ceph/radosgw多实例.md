# radosgw多实例

一台物理主机上面可以通过配置不同的端口，从而配置多个实例

# 实践过程

- 修改配置文件
	<pre>
[client.rgw.host671]
host = host67
keyring = /var/lib/ceph/radosgw/ceph-rgw.host671/keyring
rgw socket path = /tmp/radosgw-host671.sock
log file = /var/log/ceph/ceph-rgw-host671.log
rgw data = /var/lib/ceph/radosgw/ceph-rgw.host671
rgw frontends = civetweb port=8081
</pre>

- 新建ceph auth新建radosgw用户
	<pre>
	ceph auth add client.rgw.host671 mon 'allow rw' osd 'allow rwx'</pre>
- 准备相关文件
	1. 创建 `rgw data` 
		<pre>cd /var/lib/ceph/radosgw
		mkdir ceph-rgw-host671
		touch sysvinit done
		ceph auth get-key client.rgw.host671 > keyring
		chmod 600 keyring
		cd ..
		chown -R ceph.ceph ceph-rgw-host671
		</pre> 
	2. 这里的keyring的格式如下：
		<pre>
		[client.rgw.host281]
			key = AQBEZr9ZNwApExAA03m8ggfzt6pmaH/e1aVKoA==
		</pre>
- 配置启动脚本 `/etc/init.d/radosgw
<pre>
#! /bin/sh
### BEGIN INIT INFO
# Provides:          radosgw
# Required-Start:    $remote_fs $named $network $time
# Required-Stop:     $remote_fs $named $network $time
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: radosgw RESTful rados gateway
# Description: radosgw RESTful rados gateway
### END INIT INFO

PATH=/sbin:/bin:/usr/bin

if [ -x /sbin/start-stop-daemon ]; then
    DEBIAN=1
    . /lib/lsb/init-functions
else
    . /etc/rc.d/init.d/functions
    DEBIAN=0

    # detect systemd, also check whether the systemd-run binary exists
    SYSTEMD_RUN=$(which systemd-run 2>/dev/null)
    grep -qs systemd /proc/1/comm || SYSTEMD_RUN=""
fi

daemon_is_running() {
    daemon=$1
    if pidof $daemon >/dev/null; then
        echo "$daemon is running."
        exit 0
    else
        echo "$daemon is not running."
        exit 1
    fi
}

VERBOSE=0
for opt in $*; do
    if [ "$opt" = "-v" ] || [ "$opt" = "--verbose" ]; then
       VERBOSE=1
    fi
done

# prefix for radosgw instances in ceph.conf
PREFIX='client.radosgw.'

# user to run radosgw as (if not specified in ceph.conf)
DEFAULT_USER='root'

RADOSGW=`which radosgw`
if [ ! -x "$RADOSGW" ]; then
    [ $VERBOSE -eq 1 ] && echo "$RADOSGW could not start, it is not executable."
    exit 1
fi

# list daemons, old-style and new-style
# NOTE: no support for cluster names that aren't "ceph"
dlist=`ceph-conf --list-sections $PREFIX`
if [ -d "/var/lib/ceph/radosgw" ]; then
    for d in `ls /var/lib/ceph/radosgw | grep ^ceph-`; do
	if [ -e "/var/lib/ceph/radosgw/$d/sysvinit" ]; then
	    id=`echo $d | cut -c 6-`
	    dlist="client.$id $dlist"
	fi
    done
fi

case "$1" in
    start)
        for name in $dlist
        do
            auto_start=`ceph-conf -n $name 'auto start'`
            if [ "$auto_start" = "no" ] || [ "$auto_start" = "false" ] || [ "$auto_start" = "0" ]; then
                continue
            fi

	    shortname=`echo $name | cut -c 8-`
	    if [ ! -e "/var/lib/ceph/radosgw/ceph-$shortname/sysvinit" ]; then
                # mapped to this host?
		host=`ceph-conf -n $name host`
		hostname=`hostname -s`
		if [ "$host" != "$hostname" ]; then
                    [ $VERBOSE -eq 1 ] && echo "hostname $hostname could not be found in ceph.conf:[$name], not starting."
                    continue
		fi
	    fi

            user=`ceph-conf -n $name user`
            if [ -z "$user" ]; then
                user="$DEFAULT_USER"
            fi

            log_file=`$RADOSGW -n $name --show-config-value log_file`
            if [ -n "$log_file" ]; then
                if [ ! -e "$log_file" ]; then
                    touch "$log_file"
                fi
                chown $user $log_file
            fi

            echo "Starting $name..."
	    if [ $DEBIAN -eq 1 ]; then
		start-stop-daemon --start -u $user -x $RADOSGW -p /var/run/ceph/client-$name.pid -- -n $name
	    elif [ -n "$SYSTEMD_RUN" ]; then
                $SYSTEMD_RUN -r su "$user" -c "ulimit -n 32768; $RADOSGW -n $name"
            else
		ulimit -n 32768
                daemon --user="$user" "$RADOSGW -n $name"
            fi
        done
        ;;
    reload)
        echo "Reloading $name..."
	if [ $DEBIAN -eq 1 ]; then
            start-stop-daemon --stop --signal HUP -x $RADOSGW --oknodo
	else
            killproc $RADOSGW -SIGHUP
	fi
	;;
    restart|force-reload)
        $0 stop
        $0 start
        ;;
    stop)
        timeout=0
        for name in $dlist
        do
          t=`$RADOSGW -n $name --show-config-value rgw_exit_timeout_secs`
          if [ $t -gt $timeout ]; then timeout=$t; fi
        done

	if [ $DEBIAN -eq 1 ]; then
            if [ $timeout -gt 0 ]; then TIMEOUT="-R $timeout"; fi
            start-stop-daemon --stop -x $RADOSGW -t
            start-stop-daemon --stop -x $RADOSGW --oknodo $TIMEOUT
	else
	    killproc $RADOSGW
	    while pidof $RADOSGW >/dev/null && [ $timeout -gt 0 ] ; do
		sleep 1
		timeout=$(($timeout - 1))
            done
	fi
        ;;
    status)
        daemon_is_running $RADOSGW
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|force-reload|reload|status} [-v|--verbose]" >&2
        exit 3
        ;;
esac
</pre>
- 启动服务

<pre>
/etc/init.d/radosgw restart
</pre>