# [GlusterFS](http://blog.csdn.net/zzulp/article/details/39527441)
## 理论基础
### 分布式文件系统出现
计算机通过文件系统管理、存储数据，而现在数据信息爆炸的时代中人们可以获取的数据成指数倍的增长，单纯通过增加硬盘个数来扩展计算机文件系统的存储容量的方式，已经不能满足目前的需求。

分布式文件系统可以有效解决数据的存储和管理难题，将固定于某个地点的某个文件系统，扩展到任意多个地点/多个文件系统，众多的节点组成一个文件系统网络。每个节点可以分布在不同的地点，通过网络进行节点间的通信和数据传输。人们在使用分布式文件系统时，无需关心数据是存储在哪个节点上、或者是从哪个节点从获取的，只需要像使用本地文件系统一样管理和存储文件系统中的数据。

### 典型代表NFS
NFS（Network File System）即网络文件系统，它允许网络中的计算机之间通过TCP/IP网络共享资源。在NFS的应用中，本地NFS的客户端应用可以透明地读写位于远端NFS服务器上的文件，就像访问本地文件一样。NFS的优点如下：

1. **节约使用的磁盘空间**
  客户端经常使用的数据可以集中存放在一台机器上,并使用NFS发布,那么网络内部所有计算机可以通过网络访问,不必单独存储.
2. **节约硬件资源**
  NFS还可以共享软驱,CDROM和ZIP等的存储设备,减少整个网络上的可移动设备的数量.
3. **用户主目录设定**
  对于特殊用户,如管理员等,为了管理的需要,可能会经常登录到网络中所有的计算机,若每个客户端,均保存这个用户的主目录很繁琐,而且不能保证数据的一致性.实际上,经过NFS服务的设定,然后在客户端指定这个用户的主目录位置,并自动挂载,就可以在任何计算机上使用用户主目录的文件。

#### 面临的问题

* 存储空间不足，需要更大容量的存储。
* 直接用NFS挂载存储，有一定风险，存在单点故障。
* 某些场景不能满足要求，大量的访问磁盘IO是瓶颈。

### GlusterFS 概述
GlusterFS是Scale-Out存储解决方案Gluster的核心，它是一个开源的分布式文件系统，具有强大的横向扩展能力，通过扩展能够支持数PB存储容量和处理数千客户端。GlusterFS借助TCP/IP或InfiniBand RDMA网络将物理分布的存储资源聚集在一起，使用单一全局命名空间来管理数据。GlusterFS基于可堆叠的用户空间设计，可为各种不同的数据负载提供优异的性能。

GlusterFS支持运行在任何标准IP网络上标准应用程序的标准客户端，用户可以在全局统一的命名空间中使用NFS/CIFS等标准协议来访问应用数据。GlusterFS使得用户可摆脱原有的独立、高成本的封闭存储系统，能够利用普通廉价的存储设备来部署可集中管理、横向扩展、虚拟化的存储池，存储容量可扩展至TB/PB级。
目前glusterfs 已被redhat收购，它的官方网站是：http://www.gluster.org/

###	GlusterFS 在企业中应用场景

理论和实践上分析，GlusterFS目前主要适用大文件存储场景，对于小文件尤其是海量小文件，存储效率和访问性能都表现不佳。海量小文件LOSF问题是工业界和学术界公认的难题，GlusterFS作为通用的分布式文件系统，并没有对小文件作额外的优化措施，性能不好也是可以理解的。

* Media

	文档、图片、音频、视频

* Shared storage
 
 	云存储、虚拟化存储、HPC（高性能计算）

* Big data

	日志文件、RFID（射频识别）数据


## 实验操作

### 安装

#### 修改主机名

<pre>echo "node1" > /etc/hostname
hostname node1
</pre>
#### 修改 `hosts` 文件
<pre>192.168.56.11	node1
192.168.56.12	node2
</pre>
#### 安装epel源
<pre>
wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
</pre>
#### 配置 GlusterFS 安装源
<pre>
yum install centos-release-gluster37 -y
</pre>
<pre>
[centos-gluster37]
name=CentOS-$releasever - Gluster 3.7
baseurl=http://vault.centos.org/7.2.1511/storage/x86_64/gluster-3.7/
gpgcheck=0
enabled=1
</pre>
#### 安装GlusterFS
<pre>
yum install glusterfs-server glusterfs-cli glusterfs-geo-replication -y
</pre>

### 配置
#### 查看Gluster版本信息
<pre>
glusterfs -V
</pre>
#### 启动停止服务
<pre>
systemctl start glusterd
systemctl stop glusterd
systemctl enable glusterd
</pre>
#### 存储主机加入信任存储池
<pre>
gluster peer probe node2
</pre>
> 本机不需要加入

#### 查看状态
<pre>
gluster peer status
</pre>
#### 配置前的准备工作
准备四台机器，每台机器除了系统盘外，另外再加一块硬盘，并都格式化后挂载到目录 `/storage/brick1` 下
#### 创建volume及其他操作
##### 基本卷

* Distributed
	
	分布式卷，文件通过hash算法随机的分布到由bricks组成的卷上；它其实是扩大的磁盘空间，如果有一个磁盘坏了，对应的数据也丢失，文件级RAID 0，不具有容错能力。![](http://s4.51cto.com/wyfs02/M00/84/0A/wKioL1eEY-zQ8gnyAACEmdL2VbQ263.jpg)
* Replicated

	复制式卷，类似raid1，文件同步复制到多个brick上，并发粒度是数据块；写性能下降，读性能提升；replica数必须等于volume中brick所包含的存储服务器数，可用性高;replicated模式一般不会单独使用，经常是以“Distribute+ Replicated”或“Stripe+ Replicated”的形式出现的![](http://s1.51cto.com/wyfs02/M00/84/0A/wKioL1eEZF7iQ6m6AACBoE8TzkY456.jpg)
* Striped

	条带式卷，类似与raid0，stripe数必须等于volume中brick所包含的存储服务器数，文件被分成数据块，以Round Robin的方式存储在bricks中，并发粒度是数据块，大文件性能好。 ![](http://s3.51cto.com/wyfs02/M02/84/0B/wKiom1eEZDzhRy3ZAACCRPdnnyA765.jpg)

##### 复合卷

* Distributed Striped

	分布式的条带卷，volume中brick所包含的存储服务器数必须是stripe的倍数(>=2倍)，兼顾分布式和条带式的功能。 
* Distributed Replicated

	分布式的复制卷，volume中brick所包含的存储服务器数必须是 replica 的倍数(>=2倍)，兼顾分布式和复制式的功能。
* Strip replica volume

	条带复制卷，类似RAID 10，同时具有条带卷和复制卷的特点
* Distribute strip replica

	分布式条带复制卷，是三种基本卷的复合卷

##### 创建分布式卷
<pre>
gluster volume create gv1 node1:/storage/brick1 node2:/storage/brick1 force
gluster volume start gv1
gluster volume info
mount -t glusterfs 127.0.0.1:/gv1 /mnt
mount -o mountproto=tcp -t nfs node1:/gv1 /mnt
</pre>

> 经过测试发现，写入 `/mnt` 目录下的文件在两台机器的 `/storage/brick1` 目录下都存在，但文件内容只能在一台机器上，另外一台机器只是一个空文件，并且可以发现两台机器上这两个目录的大小是不同的;并且还有一点，发现手动写入的文件并不能快速地同步到另外一台机器上的 `/storage/brick1`目录下

##### 创建分布式复制卷
<pre>
[root@node2 ~]# gluster volume create gv2 replica 2 node1:/storage/brick1 node2:/storage/brick1 force
volume create: gv2: success: please start the volume to access data
[root@node2 ~]# gluster volume info
 
Volume Name: gv2
Type: Replicate
Volume ID: 3450b6c2-8c58-4053-acfb-6d905af302da
Status: Created
Number of Bricks: 1 x 2 = 2
Transport-type: tcp
Bricks:
Brick1: node1:/storage/brick1
Brick2: node2:/storage/brick1
Options Reconfigured:
performance.readdir-ahead: on
[root@node2 ~]# gluster volume start gv2
volume start: gv2: success
[root@node2 ~]# gluster volume status
Status of volume: gv2
Gluster process                             TCP Port  RDMA Port  Online  Pid
------------------------------------------------------------------------------
Brick node1:/storage/brick1                 49152     0          Y       4858 
Brick node2:/storage/brick1                 49152     0          Y       4669 
NFS Server on localhost                     2049      0          Y       4698 
Self-heal Daemon on localhost               N/A       N/A        Y       4693 
NFS Server on node1                         2049      0          Y       4885 
Self-heal Daemon on node1                   N/A       N/A        Y       4894 
 
Task Status of Volume gv2
------------------------------------------------------------------------------
There are no active volume tasks
</pre>

##### 创建分布式条带卷
<pre>
root@node2 ~]# gluster volume create gv1 stripe 2 node1:/storage/brick1 node2:/storage/brick2 force
volume create: gv1: success: please start the volume to access data
[root@node2 ~]# gluster volume info
 
Volume Name: gv1
Type: Stripe
Volume ID: 49739126-583b-4d91-a614-b66244f5ae87
Status: Created
Number of Bricks: 1 x 2 = 2
Transport-type: tcp
Bricks:
Brick1: node1:/storage/brick1
Brick2: node2:/storage/brick2
Options Reconfigured:
performance.readdir-ahead: on
[root@node2 ~]# gluster volume start gv1
volume start: gv1: success
[root@node2 ~]# mount -t glusterfs node1:/gv1 /mnt
[root@node2 ~]# df -h
Filesystem      Size  Used Avail Use% Mounted on
/dev/sdc        200G   33M  200G   1% /storage/brick1
node1:/gv1      400G  1.8G  398G   1% /mnt
[root@node2 ~]# cd /mnt/
[root@node2 mnt]# dd if=/dev/zero bs=1024 count=10000 of=/mnt/10M.file
10000+0 records in
10000+0 records out
10240000 bytes (10 MB) copied, 2.06642 s, 5.0 MB/s
[root@node1 brick1]# ll -h
total 4.9M
-rw-r--r-- 2 root root 4.9M May  5 12:14 10M.file

# 扩容卷
[root@node1 brick1]# gluster volume add-brick gv1 stripe 2 node2:/storage/brick1 node1:/storage/brick2 force
Changing the 'stripe count' of the volume is not a supported feature. In some cases it may result in data loss on the volume. Also there may be issues with regular filesystem operations on the volume after the change. Do you really want to continue with 'stripe' count option ?  (y/n) y
volume add-brick: success
[root@node1 brick1]# gluster volume info
 
Volume Name: gv1
Type: **Distributed-Stripe**
Volume ID: 49739126-583b-4d91-a614-b66244f5ae87
Status: Started
Number of Bricks: 2 x 2 = 4
Transport-type: tcp
Bricks:
Brick1: node1:/storage/brick1
Brick2: node2:/storage/brick2
Brick3: node2:/storage/brick1
Brick4: node1:/storage/brick2
Options Reconfigured:
performance.readdir-ahead: on
[root@node2 brick2]# df -h
Filesystem      Size  Used Avail Use% Mounted on
/dev/sdc        200G   33M  200G   1% /storage/brick1
node1:/gv1      799G  8.5G  791G   2% /mnt
</pre>

> 给分布式复制卷和分布式条带卷中增加bricks时，你增加的bricks的数目必须是复制或者条带数目的倍数，例如：你给一个分布式复制卷的replica为2，你在增加bricks的时候数量必须为2、4、6、8等。

##### 磁盘存储的平衡

平衡布局是很有必要的，因为布局结构是静态的，当新的bricks加入现有卷，新创建的文件会分布到旧的bricks中，所以需要平衡布局结构，使新加入的bricks生效。布局平衡只是使新布局生效，并不会在新的布局移动老的数据，如果你想在新布局生效后，重新平衡卷中的数据，还需要对卷中的数据进行平衡

<pre>
[root@node2 mnt]# gluster volume rebalance gv1 start
volume rebalance: gv1: success: Rebalance on gv1 has been started successfully. Use rebalance status command to check status of the rebalance process.
ID: 88cab0e0-4e56-4c42-9c0d-433490f58855
[root@node2 mnt]# gluster volume rebalance gv1 status
                                    Node Rebalanced-files          size       scanned      failures       skipped               status  run time in h:m:s
                               ---------      -----------   -----------   -----------   -----------   -----------         ------------     --------------
                               localhost                0        0Bytes             0             0             0            completed        0:0:1
                                   node1                0        0Bytes             1             0             1            completed        0:0:1
volume rebalance: gv1: success
</pre>

rebalance操作分为两个阶段进行实际执行，即fix layout和migrate data。gluster volume rebalance目前支持以下三种应用场景：

1. Fix Layout

	用法：`gluster volume rebalance <VOLNAME> fix-layout {start|stop|status}`，修复layout以使得新旧目录下新建文件可以在新增节点上分布上。

2. Migrate Data 

	用法：`gluster volume rebalance <VOLNAME> migrate-data {start|stop|status}`，新增或缩减节点后，在卷下所有节点上进行容量负载平滑。为了提高rebalance效率，通常在执行此操作前先执行Fix Layout。

3. Fix Layout and Migrate Data 

	用法：`gluster volume rebalance <VOLNAME> {start|stop|status}`，同时执行以上两个阶段操作，先Fix Layout再Migrate Data。

##### 移除bricks

你可能想在线缩小卷的大小，例如：当硬件损坏或者网络故障的时候，你可能想在卷中移除相关的bricks。注意：当你移除bricks的时候，你在 gluster的挂载点将不能继续访问数据，只有配置文件中的信息移除后你才能继续访问bricks的数据。当移除分布式复制卷或者分布式条带卷的时候， 移除的bricks数目必须是replica或者stripe的倍数。例如：一个分布式条带卷的stripe是2，当你移除bricks的时候必须是2、 4、6、8等。

<pre>
[root@node2 mnt]# gluster volume stop gv1
Stopping volume will make its data inaccessible. Do you want to continue? (y/n) y
volume stop: gv1: success
[root@node2 storage]# cd /mnt
-bash: cd: /mnt: Transport endpoint is not connected
[root@node2 mnt]# gluster volume remove-brick gv1 node1:/storage/brick2 node2:/storage/brick1 force
Removing brick(s) can result in data loss. Do you want to Continue? (y/n) y
volume remove-brick commit force: success
[root@node2 mnt]# gluster volume start gv1
[root@node2 mnt]# df -h
Filesystem      Size  Used Avail Use% Mounted on
/dev/sdc        200G   33M  200G   1% /storage/brick1
node1:/gv1      400G  1.8G  398G   1% /mnt
</pre>

> 做这一步的时候最好是复制卷，不然可能数据会丢失

##### 删除卷
<pre>
[root@node1 brick1]# umount /mnt
[root@node1 brick1]# gluster volume stop gv1
Stopping volume will make its data inaccessible. Do you want to continue? (y/n) y
volume stop: gv1: success            
[root@node1 brick1]# gluster volume delete gv1
Deleting volume will erase all information about the volume. Do you want to continue? (y/n) y
volume delete: gv1: success
[root@node1 brick1]# gluster volume info
No volumes present
</pre>


## 构建企业级分布式存储
### 硬件要求
一般选择2U的机型，磁盘STAT盘4T，如果I/O 要求比较高，可以采购SSD固态硬盘。

为了充分保证系统的稳定性和性能，要求所有glusterfs服务器硬件配置尽量一致，尤其是硬盘数量和大小。机器的RAID卡需要带电池，缓存越大，性能越好。一般情况下，建议做RAID10，如果出于空间要求的考虑，需要做RAID5，建议最好能有1-2块硬盘的热备盘。

### 系统要求和分区划分
系统安装完成后升级到最新版本，安装的时候，不要使用LV，建议/boot分区200M,/ 分区100G、swap分区和内存一样大小，剩余空间给gluster使用，划分单独的硬盘空间。系统安装软件没有特殊要求，建议除了开发工具和基本的管理软件，其他软件一律不安装。

### 网络环境
网络要求全部千兆环境，gluster服务器至少有2块网卡，1块网卡绑定供gluster使用，剩余一块分配管理网络ip，用于系统管理。如果有条件购买万兆交换机，服务器配置万兆网卡，存储性能性能会更好。网络方面如果安全性要求较高，可以多网卡绑定。

### 服务器摆放分布

服务器主备机器要放在不同的机柜， 连接不同的交换机，即使一个机柜出现问题，还有一份数据正常访问。

![](http://i.imgur.com/HeSkfNQ.png)
![](http://i.imgur.com/02qHrVi.png)

### 构建高性能、高可用存储
一般在企业中，采用的是分布式复制卷，因为有数据备份，数据相对安全，分布式条带卷目前对glusterfs 来说没有完全成熟，存在一定的数据安全风险
#### 开户防火墙端口
一般在企业应用中Linux防火墙是打开，这些开通服务器之间访问的端口<pre>
iptables -I INPUT -p tcp --dport 24007:24011 -j ACCEPT 
iptables -I INPUT -p tcp --dport 38465:38485 -j ACCEPT
</pre>
#### GlusterFS文件系统优化
![](http://i.imgur.com/76hxH4H.png)

* Performance.quick-read：优化读取小文件的性能。
* Performance.read-ahead：用预读的方式提高读取的性能，有利于应用频繁持续性的访问文件，当应用完成当前数据块读取的时候，下一个数据块就已经准备好了。
* Performance.write-behind：在写数据时，先写入缓存内，再写入硬盘，以提高写入的性能。
* Performance.io-cache：缓存已经被读过的

**调整方法**

	gluster volume set <卷><参数>

<pre>
[root@mystorage1 gv2]# gluster volume set gv2 performance.read-ahead on
volume set: success
[root@mystorage1 gv2]# gluster volume set gv2 performance.cache-size 256MB
volume set: success
[root@mystorage1 gv2]# gluster volume info gv2
 
Volume Name: gv2
Type: Replicate
Volume ID: 7e06f87d-498a-441b-a9c5-13bdac78670c
Status: Started
Number of Bricks: 1 x 2 = 2
Transport-type: tcp
Bricks:
Brick1: mystorage1:/storage/brick2
Brick2: mystorage2:/storage/brick2
Options Reconfigured:
performance.cache-size: 256MB
performance.read-ahead: on
performance.readdir-ahead: on
</pre>
### 监控及日常维护
使用zabbix自带模板即可。CPU、内存、主机存活、磁盘空间、主机运行时间、系统load等。日常情况要查看服务器的监控值，遇到报警要及时处理。

<pre>
# gluster volume status nfsp （看看这个节点有没有在线）

# gluster volume heal gv2 full （启动完全修复）

# gluster volume heal gv2 info  （查看需要修复的文件）

# gluster volume heal gv2 info healed  （查看修复成功的文件）

# gluster volume heal gv2 info heal-failed  （查看修复失败的文件）

# gluster volume heal gv2 info split-brain  （查看脑裂的文件）

# gluster volume quota gv2 enable      -- 激活 quota 功能   
# gluster volume quota gv2 disable     -- 关闭 quota 功能   
# gluster volume quota gv2 limit-usage /data 10GB --/gv2/data  目录限制   
# gluster volume quota gv2 list        --quota 信息列表   
# gluster volume quota gv2 list /data  -- 限制目录的 quota 信息   
# gluster volume set gv2 features.quota-timeout 5 -- 设置信息的超时时间   
# gluster volume quota gv2 remove /data  –删除某个目录的 quota 设置         
备注：   
1 ） quota 功能，主要是对挂载点下的某个目录进行空间限额。   如 :/mnt/glusterfs/data 目录 . 而不是对组成卷组的空间进行限制
</pre>

## 生产环境遇到常见故障处理
### 硬盘故障
因为底层做了raid配置，有硬件故障，直接更换硬盘，会自动同步数据。

如果没有做raid的处理方法：

正常node执行gluster volume status 记录故障节点uuid,执行`getfattr -d -m '.*'  /brick`,记录 `trusted.glusterfs.volume-id`及`trusted.gfid`
<pre>
[root@mystorage1 gv2]# getfattr -d -m '.*'  /storage/brick2
getfattr: Removing leading '/' from absolute path names
# file: storage/brick2
trusted.afr.dirty=0sAAAAAAAAAAAAAAAA
trusted.afr.gv2-client-1=0sAAAAAAAAAAAAAAAA
trusted.gfid=0sAAAAAAAAAAAAAAAAAAAAAQ==
trusted.glusterfs.dht=0sAAAAAQAAAAAAAAAA/////w==
trusted.glusterfs.dht.commithash="3161453668"
trusted.glusterfs.volume-id=0sfgb4fUmKRBupxRO9rHhnDA==
</pre>
在机器上更换新磁盘，挂载目录,执行如下命令
<pre>
setfattr -n trusted.glusterfs.volume-id -v 记录值  brickpath  
setfattr -n trusted.gfid -v 记录值  brickpath
service glusterd restart
</pre>
### 一台主机故障
一台节点故障的情况包括以下情况：

1. 物理故障；
2. 同时有多块硬盘故障，造成数据丢失；
3. 系统损坏不可修复。

解决方法：

找一台完全一样的机器，至少要保证硬盘数量和大小一致，安装系统，配置和故障机同样的ip，安装gluster软件，保证配置都一样，在其他健康的节点上执行命令gluster peer status，查看故障服务器的uuid，
<pre>
[root@mystorage1 gv2]# gluster peer status
Number of Peers: 3
Hostname: mystorage2
Uuid: 2e3b51aa-45b2-4cc0-bc44-457d42210ff1
State: Peer in Cluster(Disconnected)
</pre>
修改新加机器的`/var/lib/glusterd/glusterd.info`和故障机器的一样
<pre>
cat /var/lib/glusterd/glusterd.info
UUID= 2e3b51aa-45b2-4cc0-bc44-457d42210ff1
</pre>
在新机器 挂载目录上执行磁盘故障的操作,在任意节点上执行
<pre>
root@drbd01 ~]# gluster volume heal gv1 full
Launching Heal operation on volume gv2 has been successful
</pre>就会自动开始同步，但是同步的时候会影响整个系统的性能。

可以查看状态
<pre>[root@drbd01 ~]# gluster volume heal gv2 info
Gathering Heal info on volume gv2 has been successful</pre>

# 支持openstack cinder服务的一些配置
<pre>
[DEFAULT]
enabled_backends = glusterfs
[glusterfs]                                                          #最后添加
volume_driver = cinder.volume.drivers.glusterfs.GlusterfsDriver      #驱动  
glusterfs_shares_config = /etc/cinder/shares.conf                    #glusterfs存储
glusterfs_mount_point_base = /var/lib/cinder/volumes                 #挂载点
volume_backend_name = glusterfs                                      #后端名字，用于在controller上和cinder的type结合@@
</pre>
<pre>
[root@linux-node1 ~]# cat /etc/cinder/shares.conf
192.168.33.11:/demo
</pre>
<pre>
[root@linux-node1 ~]# mount
192.168.33.11:/demo on /var/lib/cinder/mnt/4ac2acc000ff60653979b4a905bdecb3 type fuse.glusterfs (rw,default_permissions,allow_other,max_read=131072)
</pre>
见到过的卷类型

网卡 | 卷类型 | 环境
--- |
万兆 | replicate | 虚拟机
|Striped-Replicate|实体机