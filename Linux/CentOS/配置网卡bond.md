# 配置网卡bond
## 真实网卡1
<pre>
[root@host62 network-scripts]# cat ifcfg-ens3f1
TYPE=Ethernet
BOOTPROTO=static
DEFROUTE=yes
PEERDNS=yes
PEERROUTES=yes
IPV4_FAILURE_FATAL=no
IPV6INIT=yes
IPV6_AUTOCONF=yes
IPV6_DEFROUTE=yes
IPV6_PEERDNS=yes
IPV6_PEERROUTES=yes
IPV6_FAILURE_FATAL=no
NAME=ens3f1
DEVICE=ens3f1
ONBOOT=yes
MASTER=bond1
SLAVE=yes
</pre>
## 真实网卡2
<pre>
[root@host62 network-scripts]# cat ifcfg-ens4f0
TYPE=Ethernet
BOOTPROTO=static
DEFROUTE=yes
PEERDNS=yes
PEERROUTES=yes
IPV4_FAILURE_FATAL=no
IPV6INIT=yes
IPV6_AUTOCONF=yes
IPV6_DEFROUTE=yes
IPV6_PEERDNS=yes
IPV6_PEERROUTES=yes
IPV6_FAILURE_FATAL=no
NAME=ens4f0
DEVICE=ens4f0
ONBOOT=yes
MASTER=bond1
SLAVE=yes
</pre>
## 虚拟网卡bond1
<pre>
[root@host62 network-scripts]# cat ifcfg-bond1
DEVICE=bond1
NAME=bond1
TYPE=Ethernet
ONBOOT=yes
BOOTPROTO=static
IPADDR=10.22.0.62
PREFIX=17
BONDING_OPTS='mode=6 miimon=100'
NM_CONTROLLED=no
IPV6INIT=no
</pre>