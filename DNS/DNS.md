
### 安装

	yum install bind-utils bind bind-devel bind-chroot -y
	[root@bogon ~]# rpm -qa|grep bind
	bind-utils-9.8.2-0.47.rc1.el6.x86_64
	bind-libs-9.8.2-0.47.rc1.el6.x86_64
	bind-9.8.2-0.47.rc1.el6.x86_64
	bind-devel-9.8.2-0.47.rc1.el6.x86_64
	bind-chroot-9.8.2-0.47.rc1.el6.x86_64

### 配置文件
	/etc/named.conf
	[root@bogon ~]# cat /etc/named.conf 
	options {
	  version "1.1.1";
	  listen-on port 53 {any;};
	  directory "/var/named/chroot/etc/";
	  pid-file "/var/named/chroot/var/run/named/named.pid";
	  allow-query { any; };
	  Dump-file "/var/named/chroot/var/log/binddump.db";
	  Statistics-file "/var/named/chroot/var/log/named_stats";
	  zone-statistics yes;
	  memstatistics-file "log/mem_stats";
	  empty-zones-enable no;
	  forwarders {202.106.196.115;8.8.8.8; };
	};
	
	key "rndc-key" {
	        algorithm hmac-md5;
	        secret "Eqw4hClGExUWeDkKBX/pBg==";
	};
	
	controls {
	       inet 127.0.0.1 port 953
	               allow { 127.0.0.1; } keys { "rndc-key"; };
	 };
	
	logging {
	  channel warning {
	    file "/var/named/chroot/var/log/dns_warning" versions 10 size 10m;
	    severity warning;
	    print-category yes;
	    print-severity yes;
	    print-time yes;
	  };
	  channel general_dns {
	    file "/var/named/chroot/var/log/dns_log" versions 10 size 100m;
	    severity info;
	    print-category yes;
	    print-severity yes;
	    print-time yes;
	  };
	  category default {
	    warning;
	  };
	  category queries {
	    general_dns;
	  };
	};
	
	include "/var/named/chroot/etc/view.conf";
	
	[root@bogon ~]# cat /etc/rndc.key 
	key "rndc-key" {
	        algorithm hmac-md5;
	        secret "Eqw4hClGExUWeDkKBX/pBg==";
	};

	[root@bogon ~]# cat /etc/rndc.conf 
	key "rndc-key" {
	        algorithm hmac-md5;
	        secret "Eqw4hClGExUWeDkKBX/pBg==";
	};
	
	options {
	        default-key "rndc-key";
	        default-server 127.0.0.1;
	        default-port 953;
	};

	cat /var/named/chroot/etc/view.conf
	view "View" {
	  zone "lnh.com" {
	        type    master;
	        file    "lnh.com.zone";
	        allow-transfer {
	                10.255.253.211;
	        };
	        notify  yes;
	        also-notify {
	                10.255.253.211;
	        };
	  };
	};

	cat /var/named/chroot/etc/lnh.com.zone
	$ORIGIN .
	$TTL 3600       ; 1 hour
	lnh.com                  IN SOA  op.lnh.com. dns.lnh.com. (
	                                2000       ; serial
	                                900        ; refresh (15 minutes)
	                                600        ; retry (10 minutes)
	                                86400      ; expire (1 day)
	                                3600       ; minimum (1 hour)
	                                )
	                        NS      op.lnh.com.
	$ORIGIN lnh.com.
	shanks              A       1.2.3.4
	op              A       1.2.3.4

修改目录权限，并启动服务 

	cd /var && chown -R named.named named/
	/etc/init.d/named start
	chkconfig named on
	netstat -nltp
	dig @127.0.0.1 a.lnh.com

如果不指定，怎么查看现在用的是哪个DNS

	cat /etc/resolv.conf

## 主从同步
### 从机

	yum install bind-utils bind bind-devel bind-chroot -y

/etc/named.conf   跟上面一样

/etc/rndc.key

/etc/rndc.conf

key生成的方法

下面开始不一样了

	cat /var/named/chroot/etc/view.conf
	view "SlaveView" {
	        zone "lnh.com" {
	             type    slave;
	             masters {192.168.56.13; };
	             file    "slave.lnh.com.zone";
	        };
	};


修改主的配置文件

	[root@bogon var]# vim /var/named/chroot/etc/view.conf 
	view "View" {
	  zone "lnh.com" {
	        type    master;
	        file    "lnh.com.zone";
	        allow-transfer {
	                192.168.56.14;
	        };
	        notify  yes;
	        also-notify {
	                192.168.56.14;
	        };
	  };
	};
	rndc reload

slave执行
	
	cd /var && chown -R named.named named/
	/etc/init.d/named start
	chkconfig named on

当在 `/var/named/chroot/etc` 目录下有 `slave.lnh.com.zone` 这个文件时就说明同步成功了


### 添加A、CNAME、MX、PTR记录

所有操作都在master上做操作

	[root@bogon etc]# dig @192.168.56.13 mx.lnh.com
	
	; <<>> DiG 9.8.2rc1-RedHat-9.8.2-0.47.rc1.el6 <<>> @192.168.56.13 mx.lnh.com
	; (1 server found)
	;; global options: +cmd
	;; Got answer:
	;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 41752
	;; flags: qr aa rd ra; QUERY: 1, ANSWER: 0, AUTHORITY: 1, ADDITIONAL: 0
	
	;; QUESTION SECTION:
	;mx.lnh.com.			IN	A
	
	;; AUTHORITY SECTION:
	lnh.com.		3600	IN	SOA	op.lnh.com. dns.lnh.com. 2003 900 600 86400 3600
	
	;; Query time: 1 msec
	;; SERVER: 192.168.56.13#53(192.168.56.13)
	;; WHEN: Sat Jul  9 11:36:26 2016
	;; MSG SIZE  rcvd: 71
	
	[root@bogon etc]# host mx.lnh.com 127.0.0.1
	Using domain server:
	Name: 127.0.0.1
	Address: 127.0.0.1#53
	Aliases: 
	
	mx.lnh.com mail is handled by 5 192.168.122.101.lnh.com.

上面是做完MX记录后的检查，可以发现还是host靠谱一点

#### 反向解析

	[root@bogon etc]# cat view.conf 
	view "View" {
	  zone "lnh.com" {
	        type    master;
	        file    "lnh.com.zone";
	        allow-transfer {
	                192.168.56.14;
	        };
	        notify  yes;
	        also-notify {
	                192.168.56.14;
	        };
	  };
	  zone "168.192.in-addr.arpa" {
	        type    master;
	        file    "168.192.zone";
	        allow-transfer {
	                192.168.56.14;
	        };
	        notify  yes;
	        also-notify {
	                192.168.56.14;
	        };
	  };
	};

	[root@bogon etc]# cat 168.192.zone 
	$TTL 3600       ; 1 hour
	@                  IN SOA  op.lnh.com. dns.lnh.com. (
	                                2004       ; serial
	                                900        ; refresh (15 minutes)
	                                600        ; retry (10 minutes)
	                                86400      ; expire (1 day)
	                                3600       ; minimum (1 hour)
	                                )
	                        NS      op.lnh.com.
	102.122     IN      PTR     a.lnh.com.
	chown named.named 168.192.zone
	rndc reload

修改从节点

	[root@bogon etc]# cat view.conf 
	view "SlaveView" {
	        zone "lnh.com" {
	             type    slave;
	             masters {192.168.56.13; };
	             file    "slave.lnh.com.zone";
	        };
		zone "168.192.in-addr.arpa" {
	             type    slave;
	             masters {10.5.35.14; };
	             file    "slave.168.192.zone";
	        };
	};
	rndc reload

	[root@bogon etc]# host 192.168.122.102 127.0.0.1
	Using domain server:
	Name: 127.0.0.1
	Address: 127.0.0.1#53
	Aliases: 
	
	102.122.168.192.in-addr.arpa domain name pointer a.lnh.com.
	[root@bogon etc]# host 192.168.122.102 192.168.56.13
	Using domain server:
	Name: 192.168.56.13
	Address: 192.168.56.13#53
	Aliases: 
	
	102.122.168.192.in-addr.arpa domain name pointer a.lnh.com.

## 通过DNS实现负载均衡

有负载均衡的功能，但是只是简单的轮询，还有就是不能对后端节点进行检测


### 配置DNS视图（智能DNS）

原理：根据客户端的IP来智能DNS；避免

负载均衡

master节点：

<pre>
[root@bogon etc]# cat /var/named/chroot/etc/named.conf 
options {
  version "1.1.1";
  listen-on port 53 {any;};
  directory "/var/named/chroot/etc/";
  pid-file "/var/named/chroot/var/run/named/named.pid";
  allow-query { any; };
  Dump-file "/var/named/chroot/var/log/binddump.db";
  Statistics-file "/var/named/chroot/var/log/named_stats";
  zone-statistics yes;
  memstatistics-file "log/mem_stats";
  empty-zones-enable no;
  forwarders {202.106.196.115;8.8.8.8; };
};

key "rndc-key" {
        algorithm hmac-md5;
        secret "Eqw4hClGExUWeDkKBX/pBg==";
};

controls {
       inet 127.0.0.1 port 953
               allow { 127.0.0.1; } keys { "rndc-key"; };
 };

logging {
  channel warning {
    file "/var/named/chroot/var/log/dns_warning" versions 10 size 10m;
    severity warning;
    print-category yes;
    print-severity yes;
    print-time yes;
  };
  channel general_dns {
    file "/var/named/chroot/var/log/dns_log" versions 10 size 100m;
    severity info;
    print-category yes;
    print-severity yes;
    print-time yes;
  };
  category default {
    warning;
  };
  category queries {
    general_dns;
  };
};

acl group1 {
  192.168.56.13;
};

acl group2 {
  192.168.56.14;
};

include "/var/named/chroot/etc/view.conf";
</pre>

如果出现IP段以外的IP的话，就去默认的。

<pre>
[root@bogon etc]# cat view.conf 
view "GROUP1" {
  match-clients { group1; };
  zone "viewlnh.com" {
    type master;
    file "group1.viewlnh.com.zone";
  };
};

view "GROUP2" {
  match-clients { group2; };
  zone "viewlnh.com" {
    type master;
    file "group2.viewlnh.com.zone";
  };
};
</pre>

<pre>
vim /var/named/chroot/etc/group1.viewlnh.com.zone
$ORIGIN .
$TTL 3600       ; 1 hour
viewlnh.com                  IN SOA  op.viewlnh.com. dns.viewlnh.com. (
                                2005       ; serial
                                900        ; refresh (15 minutes)
                                600        ; retry (10 minutes)
                                86400      ; expire (1 day)
                                3600       ; minimum (1 hour)
                                )
                        NS      op.viewlnh.com.
$ORIGIN viewlnh.com.
op                 A       192.168.122.1
view               A       192.168.122.1
</pre>

<pre>
vim /var/named/chroot/etc/group2.viewlnh.com.zone 
$ORIGIN .
$TTL 3600       ; 1 hour
viewlnh.com                  IN SOA  op.viewlnh.com. dns.viewlnh.com. (
                                2005       ; serial
                                900        ; refresh (15 minutes)
                                600        ; retry (10 minutes)
                                86400      ; expire (1 day)
                                3600       ; minimum (1 hour)
                                )
                        NS      op.viewlnh.com.
$ORIGIN viewlnh.com.
op                 A       192.168.122.2
view               A       192.168.122.2
</pre>

修改文件所属

<pre>
chown named.named /var/named/chroot/etc/group*.zone
rndc reload
</pre>

再配置主从

<pre>
host view.viewlnh.com 192.168.56.13
</pre>


acl group11 {
	*
	file
}


## 压测小练习

<pre>
cd /usr/local/src
wget http://ftp.isc.org/isc/bind9/9.7.3/bind-9.7.3.tar.gz
tar xf bind-9.7.3.tar.gz
cd /usr/local/src/bind-9.7.3/contrib/queryperf
./configure
make
cp queryperf /usr/bin/
/usr/bin/queryperf -d test.txt -s 8.8.8.8
</pre>

## DNS监控

### 系统基础性能监控

自带模板

### LOOPBACK地址绑定状态监控

该架构中，dnsserver在集群中充当realserver的角色，在dr中，需要绑定loopback地址方能通信，因此当loopback地址没有绑定上时，lvs健康检测通过，但是当请求到达dnsserver时，请求被拒绝，dns集群出现异常

### DNS数据与MASTER一致性监控

两部分：

1. 通过写zabbix自定义discovery,扫出dns配置中所有zone,然后分别对比slave和master每个zone的serial值，当slave与master的值持续5分钟不一致时报警
2. 写脚本，每15分钟扫一遍master上所有域名解析结果，与每个slave的结果做对比，当出现结果不一致情况时报警

### DNS响应时间监控

远端一组主机跑在default下，通过dig命令检测dnsserver的响应时间

	dig @127.0.0.1 view.viewlnh.com

在这个命令里面有一个Query time，通过它来做监控

### DNS每秒请求数监控

rndc stats

### DNS可用性监控

远端一组主机跑在fullnat下，通过host命令检测dnsserver的可用性，脚本与lvs健康检测脚本类似 

当当网监控zabbix，10000台机器以下zabbix能撑住 

2.0和3.0两个版本

主要是磁盘和网卡

https://github.com/shanks1127/dns

## 公网解析

### 安装脚本 

<pre>
DNS安装脚本YUM版
#!/bin/bash
####################################################################
# Auto install bind
# Create Date :  2012-11-28
# Written by :shanks
# Organization:  DangDang
####################################################################

IN_Face=`route -n |awk '{if($4~/UG/){print $8}}'|head -n 1`
Local_IP=`/sbin/ifconfig|grep -B1 -C1 -w "${IN_Face}"|grep -w 'inet addr'|awk -F: '{print $2}'|awk '{print $1}'`

cd /usr/local/src/
yum -y install bind-utils bind bind-devel bind-chroot bind-libs >>/tmp/init_sn.log -y && rndc-confgen -r /dev/urandom -a || exit 1
  # ***config /etc/named.conf***
cat << shanks1  > /etc/named.conf
options {
  version "1.1.1";
  listen-on port 53 {any;};
  directory "/var/named/chroot/etc/";
  pid-file "/var/named/chroot/var/run/named/named.pid";
  allow-query { any; };
  Dump-file "/var/named/chroot/var/log/binddump.db";
  Statistics-file "/var/named/chroot/var/log/named_stats";
  zone-statistics yes;
  memstatistics-file "log/mem_stats";
  empty-zones-enable no;
  forwarders {202.106.196.115;8.8.8.8; };
};

key "rndc-key" {
        algorithm hmac-md5;
        secret "Eqw4hClGExUWeDkKBX/pBg==";
};

controls {
       inet 127.0.0.1 port 953
               allow { 127.0.0.1; } keys { "rndc-key"; };
 };

logging {
  channel warning {
    file "/var/named/chroot/var/log/dns_warning" versions 10 size 10m;
    severity warning;
    print-category yes;
    print-severity yes;
    print-time yes;
  };
  channel general_dns {
    file "/var/named/chroot/var/log/dns_log" versions 10 size 100m;
    severity info;
    print-category yes;
    print-severity yes;
    print-time yes;
  };
  category default {
    warning;
  };
  category queries {
    general_dns;
  };
};

include "/var/named/chroot/etc/view.conf";

shanks1
# ***config /etc/rndc.key***
cat << shanks2  > /etc/rndc.key
key "rndc-key" {
        algorithm hmac-md5;
        secret "Eqw4hClGExUWeDkKBX/pBg==";
};
shanks2
# ***config /etc/rndc.conf***
cat << shanks3  > /etc/rndc.conf
# Start of rndc.conf
key "rndc-key" {
        algorithm hmac-md5;
        secret "Eqw4hClGExUWeDkKBX/pBg==";
};

options {
        default-key "rndc-key";
        default-server 127.0.0.1;
        default-port 953;
};
shanks3
# ***config /var/named/chroot/etc/view.conf***
cat << shanks4  > /var/named/chroot/etc/view.conf
view "View" {
             allow-transfer {
                #dns-ip-list; 
        };      
             notify  yes;
             also-notify {
                #dns-ip-list; 
        };
       
#  ixfr-from-differences yes;
zone "com" {
        type    master;
        file    "com.zone";
        allow-transfer {
                10.255.253.211;
        };
        notify  yes;
        also-notify {
                10.255.253.211;
        };
  };
        zone "forward.com" {
             type    forward;
              forwarders { 10.255.253.220; };
        };
};
shanks4
# ***config  /var/named/chroot/etc/com.zone***
cat << shanks5  >  /var/named/chroot/etc/com.zone
\$ORIGIN .
\$TTL 3600       ; 1 hour
com                  IN SOA  op.shanks.com. dns.shanks.com. (
                                2000       ; serial
                                900        ; refresh (15 minutes)
                                600        ; retry (10 minutes)
                                86400      ; expire (1 day)
                                3600       ; minimum (1 hour)
                                )
                        NS      op.shanks.com.
\$ORIGIN com.
shanks              A       1.2.3.4
shanks5
cd /var && chown -R named.named named/
/etc/init.d/named start
chkconfig named on
#check install status.
check_cmd=`host  -s -W 0.5 shanks.com 127.0.0.1|grep "1.2.3.4"`
if [ -z "${check_cmd}" ]
then
  echo "<ERROR!> hey,man.install bind --- ERROR!"
  exit 5
else
  echo "<OK> hey,man.install bind --- ok."
  rndc stats
fi

if [ -f /tmp/Install_bind.sh ]
then
  rm -rf /tmp/Install_bind.sh
fi
DNS安装脚本9.9版（编译版本）
#!/bin/bash
####################################################################
# Auto install bind
# Create Date :  2012-11-28
# Written by :shanks
# Organization:  DangDang
####################################################################

IN_Face=`route -n |awk '{if($4~/UG/){print $8}}'|head -n 1`
Local_IP=`/sbin/ifconfig|grep -B1 -C1 -w "${IN_Face}"|grep -w 'inet addr'|awk -F: '{print $2}'|awk '{print $1}'`

prefix='/usr/local/bind'

cd /usr/local/src/ && wget http://192.168.1.9/soft/dns/9.9/bind-9.9.7-P2.tar.gz && tar zxf bind-9.9.7-P2.tar.gz
if [ -d '/usr/local/src/bind-9.9.7-P2' ]
then
  cd /usr/local/src/bind-9.9.7-P2 && ./configure --prefix=/usr/local/bind --enable-threads --with-libtool && make && make install
  REAV=$?
  if [ ${REAV} != 0 ]
  then
    echo 'bind make faild!!!'
    exit 2
  fi
else
  echo 'bind src get filed!!!'
  exit 1
fi
  # ***config /etc/named.conf***
cat << shanks1  > ${prefix}/etc/named.conf
options {
  version "1.1.1";
  listen-on port 53 {any;};
  directory "${prefix}/etc/";
  pid-file "${prefix}/var/run/named.pid";
  allow-query { any; };
  Dump-file "${prefix}/var/binddump.db";
  Statistics-file "${prefix}/var/named_stats";
  zone-statistics yes;
  memstatistics-file "var/mem_stats";
  empty-zones-enable no;
  masterfile-format text;
#  allow-update {none;}; 
#  allow-recursion {any;}; 
#  serial-query-rate 100;
#  recursion no;
#  dnssec-enable yes;
};

key "rndc-key" {
        algorithm hmac-md5;
        secret "Eqw4hClGExUWeDkKBX/pBg==";
};

controls {
       inet 127.0.0.1 port 953
               allow { 127.0.0.1; } keys { "rndc-key"; };
 };

logging {
  channel warning {
    file "${prefix}/var/dns_warning" versions 10 size 10m;
    #file "${prefix}/var/dns_warning";
    severity warning;
    print-category yes;
    print-severity yes;
    print-time yes;
  };
  channel general_dns {
    file "${prefix}/var/dns_log" versions 10 size 50m;
    #file "${prefix}/var/dns_log";
    severity info;
    print-category yes;
    print-severity yes;
    print-time yes;
  };
  category default {
    warning;
  };
  category queries {
    general_dns;
  };
};

include "${prefix}/etc/view.conf";

shanks1
# ***config /etc/rndc.key***
cat << shanks2  > /etc/rndc.key
key "rndc-key" {
        algorithm hmac-md5;
        secret "Eqw4hClGExUWeDkKBX/pBg==";
};
shanks2
# ***config /etc/rndc.conf***
cat << shanks3  > ${prefix}/etc/rndc.conf
# Start of rndc.conf
key "rndc-key" {
        algorithm hmac-md5;
        secret "Eqw4hClGExUWeDkKBX/pBg==";
};

options {
        default-key "rndc-key";
        default-server 127.0.0.1;
        default-port 953;
};
shanks3
# ***config ${prefix}/etc/view.conf***
cat << shanks4  > ${prefix}/etc/view.conf
view "View" {
             allow-transfer {
                #dns-ip-list; 
        };      
             notify  yes;
             also-notify {
                #dns-ip-list; 
        };
       
#  ixfr-from-differences yes;
zone "com" {
        type    master;
        file    "com.zone";
        allow-transfer {
                10.255.253.211;
        };
        notify  yes;
        also-notify {
                10.255.253.211;
        };
  };
        zone "forward.com" {
             type    forward;
             forwarders { 10.255.253.220; };
        };
};
shanks4
# ***config  ${prefix}/etc/com.zone***
cat << shanks5  >  ${prefix}/etc/com.zone
\$ORIGIN .
\$TTL 3600       ; 1 hour
com                  IN SOA  op.shanks.com. dns.shanks.com. (
                                2000       ; serial
                                900        ; refresh (15 minutes)
                                600        ; retry (10 minutes)
                                86400      ; expire (1 day)
                                3600       ; minimum (1 hour)
                                )
                        NS      dns.shanks.com.
\$ORIGIN com.
shanks              A       1.2.3.4
shanks5
useradd named -s /sbin/nologin
cd /usr/local && chown -R named.named bind/
if [ -f /etc/init.d/named ]
then
  rm -rf /etc/init.d/named
fi
wget -q http://192.168.1.9/soft/dns/9.9/named -O /etc/init.d/named && chmod +x /etc/init.d/named
/etc/init.d/named start
ln -s ${prefix}/sbin/rndc /usr/bin/rndc
ln -s ${prefix}/bin/host /usr/bin/host
ln -s ${prefix}/bin/dig /usr/bin/dig
chkconfig named on
#check install status.
check_cmd=`host  -s -W 0.5 shanks.com 127.0.0.1|grep "1.2.3.4"`
if [ -z "${check_cmd}" ]
then
  echo "<ERROR!> hey,man.install bind --- ERROR!"
else
  echo "<OK> hey,man.install bind --- ok."
fi

if [ -f /tmp/Install_bind.sh ]
then
  rm -rf /tmp/Install_bind.sh
fi

</pre>
