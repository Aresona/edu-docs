# Centos使用openvpn

* 安装openvpn客户端 

<PRE>
wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
yum install openvpn -y
</PRE>

* 上传配置文件并解压（一般会放在 `/etc/openvpn` 目录下）

<pre>
unzip config.zip
mv config/* .
</pre>

* 启动openvpn客户端

<pre>
openvpn --daemon --cd /etc/openvpn --config client.ovpn --log-append /etc/openvpn/openvpn.log
</pre>

**注意**

当出现虚拟网卡说明成功
<pre>
[root@zabbix openvpn]# ifconfig 
tun0: flags=4305<UP,POINTOPOINT,RUNNING,NOARP,MULTICAST>  mtu 1500
        inet 10.8.0.14  netmask 255.255.255.255  destination 10.8.0.13
        unspec 00-00-00-00-00-00-00-00-00-00-00-00-00-00-00-00  txqueuelen 100  (UNSPEC)
        RX packets 2  bytes 168 (168.0 B)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 2  bytes 168 (168.0 B)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
</pre>

* 测试

<pre>
[root@zabbix openvpn]# ping -c 1 192.168.0.51
PING 192.168.0.51 (192.168.0.51) 56(84) bytes of data.
64 bytes from 192.168.0.51: icmp_seq=1 ttl=127 time=4.63 ms

--- 192.168.0.51 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 4.630/4.630/4.630/0.000 ms
</pre>
