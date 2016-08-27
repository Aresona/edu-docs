# 回顾
> openstack的服务都需要在keystone注册，注册包括注册实体，注册三个endpoint，有管理、公网、内网的三种角色。
> 
> glance镜像组件有 `glance-api` 、 `glance-registry`、 `image store`;默认存储在本地，没有存储驱动，驱动是一个框架，可以支持不同的组件。Glance-api：接受云系统镜像的创建、删除、读取请求。

> nova是代码量最多的一个组件，它的API是接收和响应外部请求的，之间的沟通也是通过rabbitmq的；nova scheduler是nova的调度组件，用来决策虚拟机创建在哪个主机上。它分为两个步骤：过滤和计算权值。

# 网络(neutron)

neutron是oepnstack中提供网络资源的，最早的时候是nova-network,它仅支持网桥，创建的类型也很简单，也就是最早的单一扁平网络和VLAN，为了支持更多的插件，做了一个quetanm组件，后来因为冲突改为neutron,支持很多商业的和oepnvswitch等插件。

**传统情况下，计算机上网需要的东西有：**

1. 计算机需要网卡
2. 需要有网络（子网）
3. 交换机、路由器，端口

**在neutron里面也有这些概念**

<pre>
[root@openstack-master ~]# neutron net-list
+--------------------------------------+------+-----------------------------------------------------+
| id                                   | name | subnets                                             |
+--------------------------------------+------+-----------------------------------------------------+
| bf67408b-f259-4245-b60a-a727b10dd5fe | flat | 6fa3d7ad-1aed-4307-873b-814f91a3c0ad 192.168.1.0/24 |
+--------------------------------------+------+-----------------------------------------------------+
</pre>
这就是一个网络，也就是上面物理环境的网络。包括一个ID，一个name;

另外还有一个概念就是子网，有了子网之后，虚拟机想上网还需要跟交换机连起来（网桥）。

brqbf67408b-f2就相当于网桥。


## openstack网络分类
* 公共网络：向租户提供访问或者API调用
* 管理网络：云中物理机之间的通信
* 存储网络：云中存储的网络，如ISCSI或GlusterFS使用
* 服务网络：虚拟机内部使用的网络

## neutron里面的网络分层
* 网络：在实际的物理环境下，我们使用交换机或者集线器把多个计算机连接起来形成了网络。在Neutron的世界里面网络也是将多个不同的云主机连接起来
* 子网：在实际的物理环境下，在一个网络中，我们可以将网络划分成多个逻辑子网，在Neutron的世界里，子网也是隶属于网络下的。
* 端口：是实际的物理环境下，每个子网或者每个网络，都有很多的端口，比如交换机端口来提供计算机连接，在Neutron的世界端口也是隶属于子网下，云主机的网卡会对应到一个端口上。
* 路由器：在实际的网络环境下，不同网络或者不同逻辑子网之间如果需要进行通信，需要通过路由器进行路由。在Neutron的实际里路由也是这个作用。用来连接不同的网络或者子网。

## 单一扁平网络
跑个物理机，装一个EXSI，桥接方式




Neutron实现了从二层到七层的功能，单一扁平网络实现的就是二层的，最早的阿里云就是一个大二层，可能会有广播风暴的问题，可以通过不让发广播来解决。大二层是最稳定的，SDN简单说就是软件定义网络，它是通过软件来做的，首先它有性能的瓶颈，现在是把SDN的流量引到SDN的交换机上。

在私有云中，一个24位的网络就支持253台机器，所以这样一个就够了。对于大一点的还可以使用VLAN，VLAN支持 `0－4096` ，虽然不够这么多，但也肯定够了。但对于公有云来说是不够的，所以公有云会用别的方案。

## Neutron的组件

* Neutron Server


* ML2(Module Layer2) plugin：它是一个公共的插件，所有网络都调用我来调用其他的网络，可以实现多个网络插件并存

* Linux Bridge

* OpenvSwitch

* 其他商业插件

* DHCP Agent：前面设备的IP池就是给这个组件使用的(dhcp_agent .ini)

## 虚拟机

KVM只能模拟CPU和内存，其他的需要通过QEMU来模拟，并且这个进程可以被调度，并且虚拟机一定会占交换机分区（它是一种机制）。

它可以被libvirtd来管理。

虚拟机的地址 `/var/lib/nova/instances/b2f39c1b-fa12-4a6b-a30a-9d4a8ed8c7a6` 在创建的时候虚拟机都有一个ID，

qcow2 写时复制，基础镜像不变，把变的放在disk里面，它的后端文件就是不变的。

在openstack里面的libvirt.xml是不能改的，因为你改了它也没什么卵用，因为它是动态生成的。


## Metadata
openstack提供了一个metadata机制，让用户可以设置虚拟机的一些属性，比如说主机名，key,ip地址等。

虚拟机到底怎么获取这个属性呢？
<pre>
$ curl http://169.254.169.254/2009-04-04/meta-data
ami-id
ami-launch-index
ami-manifest-path
block-device-mapping/
hostname
instance-action
instance-id
instance-type
local-hostname
local-ipv4
placement/
public-hostname
public-ipv4
public-keys/
reservation-id
</pre>
这个IP是最初大家给亚马逊做镜像的时候都用这个IP，openstack为了兼容亚马逊就都用这个IP。问题是这个IP怎么能通呢，
<pre>
$ ip ro li
default via 192.168.1.1 dev eth0 
169.254.169.254 via 192.168.1.235 dev eth0 
192.168.1.0/24 dev eth0  src 192.168.1.236 
</pre>
<pre>
[root@openstack-master ~]# ip netns li
qdhcp-bf67408b-f259-4245-b60a-a727b10dd5fe (id: 0)
查看网络的命名空间
[root@openstack-master ~]# ip netns exec qdhcp-bf67408b-f259-4245-b60a-a727b10dd5fe ifconfig
lo: flags=73<UP,LOOPBACK,RUNNING>  mtu 65536
        inet 127.0.0.1  netmask 255.0.0.0
        inet6 ::1  prefixlen 128  scopeid 0x10<host>
        loop  txqueuelen 0  (Local Loopback)
        RX packets 0  bytes 0 (0.0 B)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 0  bytes 0 (0.0 B)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

ns-8afba35b-6a: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 192.168.1.235  netmask 255.255.255.0  broadcast 192.168.1.255
        inet6 fe80::f816:3eff:fe93:80c8  prefixlen 64  scopeid 0x20<link>
        ether fa:16:3e:93:80:c8  txqueuelen 1000  (Ethernet)
        RX packets 80701  bytes 9283515 (8.8 MiB)
        RX errors 0  dropped 156  overruns 0  frame 0
        TX packets 81  bytes 9063 (8.8 KiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
[root@openstack-master ~]# ip netns exec qdhcp-bf67408b-f259-4245-b60a-a727b10dd5fe ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN 
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: ns-8afba35b-6a@if3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP qlen 1000
    link/ether fa:16:3e:93:80:c8 brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 192.168.1.235/24 brd 192.168.1.255 scope global ns-8afba35b-6a
       valid_lft forever preferred_lft forever
    inet 169.254.169.254/16 brd 169.254.255.255 scope global ns-8afba35b-6a
       valid_lft forever preferred_lft forever
    inet6 fe80::f816:3eff:fe93:80c8/64 scope link 
       valid_lft forever preferred_lft forever
[root@openstack-master ~]# ip netns exec qdhcp-bf67408b-f259-4245-b60a-a727b10dd5fe netstat -ntlp
Active Internet connections (only servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name    
tcp        0      0 0.0.0.0:80              0.0.0.0:*               LISTEN      63782/python2       
tcp        0      0 192.168.1.235:53        0.0.0.0:*               LISTEN      63732/dnsmasq       
tcp        0      0 169.254.169.254:53      0.0.0.0:*               LISTEN      63732/dnsmasq       
tcp6       0      0 fe80::f816:3eff:fe93:53 :::*                    LISTEN      63732/dnsmasq   
[root@openstack-master ~]# ip netns exec qdhcp-bf67408b-f259-4245-b60a-a727b10dd5fe ps -ef|grep apache
apache    38157  38146  0 Aug24 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
apache    38158  38146  0 Aug24 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
apache    38159  38146  0 Aug24 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
apache    38160  38146  0 Aug24 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
apache    38161  38146  0 Aug24 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
apache    38204  38146  0 Aug24 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
apache    40891  38146  0 Aug24 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
apache    64008  38146  0 Aug24 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
apache    64112  38146  0 Aug24 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
apache    64242  38146  0 Aug24 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
root      93417  93271  0 11:31 pts/1    00:00:00 grep --color=auto apache
</pre>

虚拟机的路由条目是谁推送的呢？

<pre>
/etc/neutron/dhcp_agent.ini
enable_isolated_metadata = True
</pre>
通过什么推送？

**DHCP**

<pre>
$ curl http://169.254.169.254/2009-04-04/meta-data/public-keys/0
openssh-key
</pre>

# DashBoard
管理openstack的方法有很多，dashborad只是其中的一种，它是通过API来通信的，所以我们可以通过命令行和dashboard来管理，dashboard必备的项目有nova、neutron、keystone、glance项目，也就是需要这四个服务先注册了。它只需要连到`keystone`就可以了

<pre>
yum install openstack-dashboard -y
</pre>

它是djago写的，
## 配置
<pre>
vim /etc/openstack-dashboard/local_settings
/KEYSTONE   (138行）
OPENSTACK_HOST = "192.168.1.230"
OPENSTACK_KEYSTONE_DEFAULT_ROLE = "user"
/ALLOW
ALLOWD_HOSTS = ['*',]
CACHES = {
	'default': {
		'BA
		'LOCATION': '192.168.1.230:11211',
	}
	
}
TIME_ZONE = "Asia/Shanghai"
systemctl restart httpd
</pre>
访问： `192.168.1.230/dashboard`
demo/demo

### 快照原理
首先在虚拟机上创建一个快照，然后把这个镜像上传到glance上面，这样以后再创建就可以基于这个镜像来创建了。


## 虚拟机创建流程
分为三个阶段：keystone认证、nova之间的组件交互、nova compute跟其他组件交互，如glance、neutron、cinder等。（最后还需要调度libvirt来创建）

## 生产过程中的细节
1. 对于计算节点来说，第一次创建虚拟机的时候会慢，因为需要glance把基础镜像放在计算节点上。
2. 计算节点上的网桥是在创建虚拟机的时候检查，如果没有才创建的；创建网桥失败通常会跟物理网卡的启动协议有关，要用static,


# Cinder
## 存储的分类

* 块存储（硬盘、磁盘阵列）：磁盘、LVM、DAS(直连式存储)、SAN
* 文件存储（NAS/NFS）
* 对象存储（SWIFT）：Ceph（分布式文件系统）

一块硬盘就是一块块设备，要用它就必须对它进行分区，并且oracle和drbd可以直接用。

## cinder
它提供的是云硬盘，它的瓶颈是网络。
### cindre组件
* cinder-api:接受API请求并将请求路由到cinder-volume来执行
* cinder-volume:响应请求，读取或写向块存储数据库为维护状态，通过信息队列机制与其他进程交互（如cinder-scheduler），或直接与上层块存储提供的硬件或软件进行交互。通过驱动结构，他可以与众多的存储提供者进行交互。
* cinder-scheduler:守护进程。类似于nova-scheduler,为存储卷的实例选取最优的块存储供应节点。

### 后端存储的支持类型
ISCSI,NFS,Glusterfs

### 安装 
控制节点
<pre>
yum install openstack-cinder python-cinderclient -y
create database cinder;
grant all on cinder.* to cinder@localhost identified by 'cinder';
grant all on cinder.* to cinder@'%' identified by 'cinder';
</pre>
### 修改配置
<pre>
/etc/cinder/cinder.conf
[database]
connection = mysql://cinder:cinder@192.168.1.230/cinder
su -s /bin/sh -c "cinder-manage db sync" cinder
connection  
mysql -h 192.168.1.230 -ucinder -pcinder -e "use cinder;show tables;"
</pre>
创建keystone里面的用户 
<pre>
source admin-openrc.sh
openstack user create --domain default --password-prompt cinder
openstack role add --project service --user cinder admin
</pre>
<pre>
vim /etc/cinder/cinder.conf
auth_strategy = keystone
[keystone_authtoken]
auth_uri = http://192.168.1.230:5000
auth_url = http://192.168.1.230:35357
auth_plugin = password
project_domain_id = default
project_name = service
username = cinder
password = cinder
rpc_backend = rabbit
[oslo_messaging_rabbit]
rabbit_host = 192.168.1.230
rabbit_port = 5672
rabbit_userid = openstack
rabbit_password = openstack
glance_host = 192.168.1.230
[oslo_concurrency]
lock_path = /var/lib/cinder/tmp
</pre>
<pre>
/etc/nova/nova.conf
[cinder]
os_region_name = RegionOne
systemctl restart openstack-nova-api.service
systemctl enable openstack-cinder-api.service openstack-cinder-scheduler.service
systemctl start openstack-cinder-api.service openstack-cinder-scheduler.service
</pre>
keystone下做注册
<pre>
cinder有两个版本都需要注册 
openstack service create --name cinder --description "Openstack Block Storage" volume
openstack service create --name cinderv2 --description "OpenStack Block Storage v2" volumev2
openstack endpoint create --region RegionOne volume public http://192.168.1.230:8776/v1/%\(tenant_id\)s
openstack endpoint create --region RegionOne volume internal http://192.168.1.230:8776/v1/%\(tenant_id\)s
openstack endpoint create --region RegionOne volume admin http://192.168.1.230:8776/v1/%\(tenant_id\)s
openstack endpoint create --region RegionOne volumev2 public http://192.168.1.230:8776/v2/%\(tenant_id\)s
openstack endpoint create --region RegionOne volumev2 internal http://192.168.1.230:8776/v2/%\(tenant_id\)s
openstack endpoint create --region RegionOne volumev2 admin http://192.168.1.230:8776/v2/%\(tenant_id\)s
</pre>
<pre>
grep '^[a-Z]' /etc/cinder/cinder.conf[root@openstack-master ~]# grep '^[a-Z]' /etc/cinder/cinder.conf
glance_host = 192.168.1.230
auth_strategy = keystone
rpc_backend = rabbit
connection = mysql://cinder:cinder@192.168.1.230/cinder
auth_uri = http://192.168.1.230:5000
auth_url = http://192.168.1.230:35357
auth_plugin = password
project_domain_id = default
project_name = service
username = cinder
password = cinder
lock_path = /var/lib/cinder/tmp
rabbit_host = 192.168.1.230
rabbit_port = 5672
rabbit_userid = openstack
rabbit_password = openstack
</pre>
#### 存储节点
这里我们后端调用的是iscsi，它的原理是通过LVM来做的，然后再通过cinder发布出去，也就是每创建一个虚拟机就生成一个LV。

这里在计算节点上加一块硬盘
<pre>
systemctl start lvm2-lvmetad.service
systemctl start lvm2-lvmetad.socket
pvcreate /dev/sdb
vgcreate cinder-volumes /dev/sdb
</pre>
<pre>
vim /etc/lvm/lvm.conf
filter = ["a/sdb/", "r/.*/"]
</pre>
<pre>
yum install openstack-cinder targetcli python-oslo-policy -y
scp 192.168.1.230:/etc/cinder/cinder.conf /etc/cinder
</pre>
<pre>
vim /etc/cinder/cinder.conf
[lvm]
volume_driver = cinder.volume.drivers.lvm.LVMVolumeDriver
volume_group = cinder-volumes
iscsi_protocol = iscsi
iscsi_helper = lioadm
[DEFAULT]
enabled_backends = lvm
systemctl enable openstack-cinder-volume.service target.service
systemctl start openstack-cinder-volume.service target.service
</pre>
> 写脚本必备技能：写日志和写LOCK文件

<pre>
cobbler repo add --name=openstack-liberty --mirror=http://mirrors.aliyun.com/centos/.. --arch=x86_64 --breed=yum
cobbler reposync
cobbler profile edit --name=xxx --repos="openstack-liberty"
</pre>
控制节点查看
<pre>
source admin-openrc.sh
cinder service-list
</pre>
> 这里需要确保时间同步 `timedatectl` 
<pre>
systemctl restart openstack-cinder-volume.service
</pre>
创建云硬盘--> demo(1G) --> 创建

计算节点
<pre>
lvdisplay
</pre>
挂载云硬盘到已经创建的主机上
管理已挂载的云硬盘 --> 选择一个云主机

> 增加云硬盘的时候可以不关机，不建议扩容和缩容，一般都再加一块，因为可能造成数据的丢失

### 云硬盘卸载
<pre>
sudo umount /data
</pre>
> 只有卸载后才能卸载云硬盘，断开链接之后就可以挂载到其他的虚拟机了。

### 从云硬盘启动一个虚拟机

先创建一个云硬盘 --> 源（选择一个镜像）--> 创建一个实例 --> 从云硬盘启动
horizon

## 修改云主机密码
<pre>
cd /etc/openstack-dashboard/local_settings
'can_set_mount_point': True,
'can_set_password': True,
'can_set_keypair': True,
</pre>
<pre>
systemctl restart httpd
</pre>
计算节点
<pre>
vim /etc/nova/nova.conf
inject_password=true
inject_key=true
systemctl restart openstack-nova-compute
</pre>

## 扩展
