# [结构化数据与非结构化数据](https://zhuanlan.zhihu.com/p/23416651)

随着图片和视频应用的大规模兴起，非结构化数据（Unstructured Data）的概念随处可见。很多人简单理解为，传统的关系数据库里存放的内容就是结构化数据，而图片、音频、视频、文档等以普通文件形式存放的数据，就是非结构化数据。这种理解没有什么大问题。数据库里的内容，一般是以字段的形式，按照一定的二维表格逻辑结构保存，内容遵循固定的格式，比较容易查询，归结为结构化数据。图片和视频等内容，巨大的数据总量和大小的不一致性导致存放在数据库中比较勉强，优化困难，一般就直接以文件的形式存放在硬盘中，被人们认为是非结构化数据。

- 结构化数据(即行数据,存储在数据库里,可以用二维表结构来逻辑表达实现的数据)
- 非结构化数据,包括所有格式的办公文档、文本、图片、XML、HTML、各类报表、图像和音频/视频信息等等

所谓半结构化数据，就是介于完全结构化数据（如关系型数据库、面向对象数据库中的数据）和完全无结构的数据（如声音、图像文件等）之间的数据，HTML文档就属于半结构化数据。它一般是自描述的，数据的结构和内容混在一起，没有明显的区分。

# ceph

对象是ceph的基础，它也是ceph的构建部件，并且ceph的对象存储很好地满足了当下及将来非结构化数据的存储需求。ceph通用存储系统同时提供块存储，文件存储和对象存储，使客户可以按需使用。

## ceph简介
Ceph提供对象存储RADOSGW(Reliable、 Autonomic、Distributed、Object Storage Gateway)、块存储RBD(Rados Block Device)、文件系统存储 Ceph FS 3种功能，以此满足不同的应用需求。其对象存储可以对接网盘应用业务等；其块设备存储可以对接(IaaS)，当前主流的云平台软件，如OpenStack等。其文件系统文件尚不成熟，官方不建议在生产环境下使用。

### Ceph的功能组件
Ceph提供了RADOS、OSD、MON、Librados、RBD、RGW和Ceph FS等功能组件，但其底层仍然使用RADOS存储来支撑上层的那些组件。

![](http://i.imgur.com/LmDjxhQ.png)

在Ceph存储中，包含了几个重要的核心组件，分别是Ceph OSD、Ceph Monitor和Ceph MDS。一个Ceph的存储至少需要一个Ceph Monitor和至少两个Ceph的OSD。运行Ceph文件系统的客户端时，Ceph的元数据服务器(MDS)是必不可少的。

- Ceph OSD： 全称是Object Storage Device,主要功能包括存储数据，处理数据的复制、恢复、回补、平衡数据分布，并将一些相关数据提供给Ceph Monitor，例如Ceph OSD心跳等。一个Ceph的存储，至少需要两个Ceph OSD来实现 active+clean健康状态和有效的保存数据的双副本（默认情况下是双副本，可以调整）。注意：每一个Disk、分区都可以成为一个OSD。
- Ceph Monitor: Ceph的监控器，主要功能是维护整个集群健康状态，提供一致性的决策，包含了Monitor map、OSD map、PG(Placement Group) map和CRUSH map.
- Ceph MDS: 全称是Ceph Metadata Server， 主要保存的是Ceph文件系统的元数据。温馨提示：Ceph的块存储和Ceph的对象存储都不需要Ceph MDS。Ceph MDS为基于POSIX文件系统的用户提供了一些基础命令，例如ls、find等命令。

### Ceph架构

Ceph底层核心是RADOS。

- RADOS： RADOS具备自我修复等特性，提供了一个可靠、自动、智能的分布式存储。
- LIBRADOWS： LIBRADOWS库允许应用程序直接访问，支持C等语言。
- RADOSGW： 是一套基于当前流行的RESTful协议的网关，并且兼容S3和Swift。
- RDB：RDB通过Linux内核客户端和QEMU/KVM驱动，来提供一个完全分布式的块设备。
- Ceph FS 功能特性是基于RADOS来实现分布式的文件系统，引入了MDS，主要为兼容POSIX文件系统提供元数据。一般都是当做文件系统来挂载。

## 存储基石RADOS

分布式对象存储系统RADOS是Ceph最为关键的技术，它是一个支持海量存储对象的分布式对象存储系统。RADOS层本身就是一个完整的对象存储系统，事实上，所有存储在Ceph系统中的用户数据最终都是由这一层来的。而Ceph的高可靠、高可扩展、高性能、高自动化等特性，本质上也是由这一层所提供的。因此，理解RADOS是理解Ceph的基础与关键。

Ceph包含以下组件：

- 分布式对象存储系统RADOS库，即LIBRADOS。
- 基于LIBRADOS实现的兼容Swift和S3的存储网关系统RADOSGW。
- 基于LIBRADOS实现的块设备驱动RBD。
- 兼容POSIX的分布式文件 Ceph FS.
- 最底层的分布式对象存储系统RADOS。

### Ceph功能模块与RADOS

Ceph组件与RADOS的关系

![](http://i.imgur.com/2oezaYT.png)

Ceph存储系统的逻辑层次结构大致划分为4部分：基础存储系统RADOS、基于RADOS实现的Ceph FS，基于RADOS的LIBRADOS层应用接口、基于LIBRADOS的应用接口RBD、RADOSGW。

#### 基础存储系统RADOS

RADOS这一层本身就是一个完整的对象存储系统，事实上，所有存储在Ceph系统中的用户数据最终都是由这一层来存储的。Ceph的很多优秀特性本质上也是借则这一层设计提供。理解RADOS是理解Ceph的基础与关键。物理上，RADOS由大量的存储设备节点缓存，每个节点拥有自己的硬件资源（CPU、内存、硬盘、网络），并运行着操作系统和文件系统。
#### 基础库LIBRADOS
LIBRADOS层的功能是对RADOS进行抽象和封装，并向上层提供API，以便直接基于RADOS进行应用开发。需要指明的是，RADOS是一个对象存储系统，因此，LIBRADOS实现的API是针对对象存储功能的。RADOS采用C++开发，所提供的原生LIBRADOS API包括C和C++两种。物理上，LIBRADOS和基于其上开发的应用位于同一台机器，因而也被称为本地API。应用调用本机上的LIBRADOS API，再由后者通过socket与RADOS集群中的节点通信并完成各种上操作。
#### 上层应用接口

Ceph上层应用接口涵盖了RADOSGW（RADOS Gateway）、RBD(Reliable Block Device)和Ceph FS，其中，RADOSGW和RBD是在LIBRADOS库的基础上提供抽象层次更高、更便于应用或客户端使用的上层接口。

其中，RADOSGW是一个提供与Amazon S3和Swift兼容的RESTful API的网关，以供相应的对象存储应用开发使用。RADOSGW提供的AIP抽象层次更高，但在类S3或Swift LIBRADOS的管理比便捷，因此，开发者应针对自己的需求选择使用。RBD则提供了一个标准的块设备接口，常用于在虚拟化的场景下为虚拟机创建volume。目前，Red Hat已经将RBD驱动集成在KVM/QEMU中，以提高虚拟机访问性能。

#### 应用层

应用层就是不同场景下对于Ceph各个应用接口的各种应用方式，例如基于LIBRADOS直接开发的对象存储应用，基于RADOSGW开发的对象存储应用，基于RBD实现的云主机硬盘等。

### RADOS架构

RADOS系统主要由两个部分组成，如下图

1. OSD： 由数目可变的大规模OSD(Object Storage Devices)组成的集群，负责存储所有的Objects数据。
2. Monitor: 由少量Monitors组成的强耦合、小规模集群，负责管理Cluster Map。其中，Cluster Map是整个RADOS系统的关键数据结构，管理集群中的所有成员、关系和属性等信息以及数据的分发。

![](http://i.imgur.com/Ad4MkyP.png)

对于RADOS系统，节点组织管理和数据分发策略均由内部的MON全权负责，因此，从Client角度设计相对比较简单，它给应用提供存储接口。

#### Monitor介绍

正如其名，Ceph Monitor是负责监视整个集群的运行状况的，这些信息都是由维护集群成员的守护程序来提供的，如各个节点之间的状态、集群配置信息。Ceph monitor map包括 `OSD Map`、`PG map`、 `MDS Map`和`CRUSH`等，这些Map被统称为`集群Map`。

Ceph Monitor是个轻量级的守护进程，通常情况下并不需要大量的系统资源，低成本、入门级的CPU，以及千兆网卡即可满足大多数场景；与此同时，Monitor节点需要有足够的磁盘空间来存储集群日志，健康集群产生几M到G的日志；然而，如果存储的需求增加时，打开低等级的日志信息的话，可能需要几个G的磁盘空间来存储日志。

一个典型的Ceph集群包含多外Monitor节点。一个多Monitor的Ceph架构通过法定人数来选择leader,并在提供一致分布式决策时使用Paxos算法集群。在Ceph集群中有多个Monitor时，集群的Monitor应该是奇数；最起码的要求是一台监视器节点，这里推荐Monitor个数是3。由于Monitor工作在法定人数，一半以上的总监视器节点应该总是可用的，以应对死机等极端情况，这是Monitor节点为N个且N为奇数的原因。所有集群Monitor节点，其中一个节点为Leader。如果Leader Monitor节点牌不可用状态，其他显示器节点有资格成为Leader。生产集群必须至少有N/2个监控节点提供高可用性。

#### Ceph OSD简介

Ceph OSD是Ceph存储集群最重要的组件，Ceph OSD将数据以对象的形式存储到集群中每个节点的物理磁盘上，完成存储用户数据的工作绝大多数都是由OSD daemon进程来实现的。

Ceph集群一般情况都包含多个OSD，对于任何读写操作请求，Client端从Ceph Monitor获取Cluster Map之后，Client将直接与OSD进行I/O操作的交互，而不再需要Ceph Monitor干预。这使得数据读写过程更为迅速，因为这些操作过程不像其他存储系统，它没有其他额外的层级数据处理。

Ceph的核心功能特性包括高可靠、自动平衡、自动恢复和一致性。对于Ceph OSD而言，基于配置的副本数，Ceph提供通过分布在多节点上的副本来实现，使得Ceph具有高可用性以及容错性。在OSD中的每个对象都有一个主副本，若干个从副本，这些副本默认情况下是分布在不同节点上的，这就是Ceph作为分布式存储系统的集中体现。每个OSD都可能性作为某些对象的主OSD，与此同时，它也可能作为某些对象的从OSD，从OSD受到主OSD的控制，然而，从OSD在某些情况也可能成为主OSD。在磁盘故障时，Ceph OSD Daemon的智能对等机制将协同其他OSD执行恢复操作。在些期间，存储对象副本的从OSD将被提升为主OSD，与些同时，新的从副本将重新生成，这样就保证了Ceph的可靠和一致。

Ceph OSD架构实现由物理磁盘驱动器、在其之上的Linux文件系统以及Ceph OSD服务组成。对Ceph OSD Daemon而言，Linux文件系统显性地支持了其扩展属性；这些文件系统的扩展属性提供了关于对象状态、快照、元数据内部信息；而访问Ceph OSD Daemon的ACL则有助于数据管理，如图


![](http://i.imgur.com/hWBQKjc.png)

Ceph OSD操作必须有一个有效的Linux分区的物理磁盘驱动器上。

在提交数据到后备存储器之前，Ceph首先将数据写入称为一个单独的存储区，该区域被称为journal，这是缓冲区分区在相同或单独磁盘作为OSD，一个单独的SSD磁盘或分区，甚至一个文件系统。在这种机制下，Ceph任何写入首先是日志，然后是后备存储。

journal持续到后备存储同步，每隔5秒。一个随机写入首先写入在上一个连续类型的journal，然后刷新到文件系统。这给了文件系统足够的时间来合并写入磁盘。使用SSD盘作为journal盘能获得相对较好的性能。在这种情况下，所有的客户端写操作都写入到超高速SSD日志，然后刷新到。所以，一般情况下，使用SSD作为OSD的journal可以有效缓冲突发负载。



#### RADOS与LIBRADOS

LIBRADOS模块是客户端用来访问RADOS对象存储设备的。Ceph存储集群提供了消息传递层协议，用于客户端与Ceph Monitor与OSD交互，LIBRADOS以库形式为Ceph Client提供了这个功能，LIBRADOS就是操作RADOS对象存储的接口。所有Ceph客户端可以用LIBRADOS或LIBRADOS里封装的相同功能和对象存储交互，LIBRBD和LIBCEPHFS就利用了此功能。你可以用LIBRADOS直接和Ceph交互（如与Ceph兼容的应用程序、Ceph接口等）下面是简单描述的步骤。

1. 获取LIBRADOS
2. 配置集群句柄
3. 创建IO上下文。


# Ceph安装

### 同步时间

### 安装包
#### 配置YUM源(可以在三个节点上同时做)
<pre>
wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
</pre>
`ceph.repo`
<pre>
[ceph]
name=Ceph packages for $basearch
baseurl=http://mirrors.163.com/ceph/rpm-hammer/el7/x86_64/
enabled=1
priority=1
gpgcheck=0
type=rpm-md
gpgkey=https://download.ceph.com/keys/release.asc

[ceph-noarch]
name=Ceph noarch packages
baseurl=http://mirrors.163.com/ceph/rpm-hammer/el7/noarch/
enabled=1
priority=1
gpgcheck=0
type=rpm-md
gpgkey=https://download.ceph.com/keys/release.asc

[ceph-source]
name=Ceph source packages
baseurl=http://mirrors.163.com/ceph/rpm-hammer/el7/SRPMS/
enabled=0
priority=1
gpgcheck=1
type=rpm-md
gpgkey=https://download.ceph.com/keys/release.asc
</pre>
#### 安装 `ceph-deploy`(管理节点)

<pre>
yum install ceph-deploy -y
</pre>

#### 配置 `hosts`文件(管理节点)
<pre>
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4 node1
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
192.168.56.11	node1
192.168.56.12	node2
192.168.56.13	node3
</pre>

#### 配置免密钥登陆(管理节点)

<pre>
ssh-keygen
ssh-copy-id node1
ssh-copy-id node2
ssh-copy-id node3
</pre>

#### 执行部署
<pre>
mkdir my-cluster
cd my-cluster
ceph-deploy new node1
ceph-deploy install node1 node2 node3
</pre>


### 手动安装
<pre>
yum install yum-plugin-priorities -y
yum install snappy leveldb gdisk python-argparse gperftools-libs -y
yum install ceph -y
</pre>

#### 创建 `ceph.conf`
<pre>
[root@node1 tmp]# cat /etc/ceph/ceph.conf 
fsid = e58bb0fd-0d89-4600-b2c2-27e1f58350cd
mon initial members = node1
mon host = 192.168.56.11
</pre>

#### 生成 `keyring`
<pre>
[root@localhost ceph]# ceph-authtool --create-keyring /tmp/ceph.mon.keyring --gen-key -n mon. --cap mon 'allow *'
creating /tmp/ceph.mon.keyring
[root@node1 tmp]# ceph-authtool -l ceph.mon.keyring 
[mon.]
	key = AQBEtRZZb7/SBRAA3VtahK9IaRuTziwHCM1pVQ==
	caps mon = "allow *"
</pre>
#### 生成管理 `keyring`
<pre>
[root@localhost ceph]# ceph-authtool --create-keyring /etc/ceph/ceph.client.admin.keyring --gen-key -n client.admin --set-uid=0 --cap mon 'allow *' --cap osd 'allow *' --cap mds 'allow'
creating /etc/ceph/ceph.client.admin.keyring
[root@node1 tmp]# cat /etc/ceph/ceph.client.admin.keyring 
[client.admin]
	key = AQAwthZZOwGxNhAADD3aVPmaAspWtq3Utar1ug==
	auid = 0
	caps mds = "allow"
	caps mon = "allow *"
	caps osd = "allow *"
</pre>
#### 添加 `cient.admin` 到 `ceph.mon.keyring`
<pre>
[root@localhost ceph]# ceph-authtool /tmp/ceph.mon.keyring --import-keyring /etc/ceph/ceph.client.admin.keyring 
importing contents of /etc/ceph/ceph.client.admin.keyring into /tmp/ceph.mon.keyring
[root@node1 tmp]# cat /tmp/ceph.mon.keyring 
[mon.]
	key = AQBEtRZZb7/SBRAA3VtahK9IaRuTziwHCM1pVQ==
	caps mon = "allow *"
[client.admin]
	key = AQAwthZZOwGxNhAADD3aVPmaAspWtq3Utar1ug==
	auid = 0
	caps mds = "allow"
	caps mon = "allow *"
	caps osd = "allow *"
</pre>
#### 通过 `hostname` `ip address` `FSID` 生成一个 `monitor map`,并保存到 `/tmp/monmap`
<pre>
[root@localhost ceph]# monmaptool --create --add node1 192.168.56.11 --fsid e58bb0fd-0d89-4600-b2c2-27e1f58350cd /tmp/monmap
monmaptool: monmap file /tmp/monmap
monmaptool: set fsid to e58bb0fd-0d89-4600-b2c2-27e1f58350cd
monmaptool: writing epoch 0 to /tmp/monmap (1 monitors)
[root@node1 tmp]# file monmap 
monmap: DBase 3 data file
[root@node1 tmp]# monmaptool --print /tmp/monmap 
monmaptool: monmap file /tmp/monmap
epoch 0
fsid e58bb0fd-0d89-4600-b2c2-27e1f58350cd
last_changed 2017-05-13 15:35:53.582619
created 2017-05-13 15:35:53.582619
0: 192.168.56.11:6789/0 mon.node1
</pre>
#### 在`mon host`上创建一个默认的数据目录
<pre>
mkdir /var/lib/ceph/mon/ceph-node1
</pre>
#### 用监视器图和密钥环组装守护进程所需的初始数据。
<pre>
[root@localhost ceph]# ceph-mon --mkfs -i node1 --monmap /tmp/monmap --keyring /tmp/ceph.mon.keyring
ceph-mon: set fsid to e58bb0fd-0d89-4600-b2c2-27e1f58350cd
ceph-mon: created monfs at /var/lib/ceph/mon/ceph-node1 for mon.node1
[root@node1 ceph-node1]# tree
.
├── keyring
└── store.db
    ├── 000003.log
    ├── CURRENT
    ├── LOCK
    ├── LOG
    └── MANIFEST-000002
</pre>
#### 补充配置文件
<pre>
[root@localhost ceph]# cat /etc/ceph/ceph.conf 
fsid = e58bb0fd-0d89-4600-b2c2-27e1f58350cd
mon initial members = node1
mon host = 192.168.56.11
public network = 192.168.56.0/24
auth cluster required = cephx
auth service required = cephx
auth client required = cephx
osd journal size = 1024
osd pool default size = 2
osd pool default min size = 1
osd pool default pg num = 333
osd pool default pgp num = 333
osd crush chooseleaf type = 1
</pre>
#### 创建一个空文件 `done` ，表示 `monitor` 已经创建，可以启动了
<pre>
touch /var/lib/ceph/mon/ceph-node1/done
</pre>
#### 创建一个空文件 `sysvinit` ，表示可以通过 `sysvinit`方式启动监视器服务
<pre>
touch /var/lib/ceph/mon/ceph-node1/sysvinit
</pre>
#### 启动 `monitor`
<pre>
[root@node1 ceph-node1]# /etc/init.d/ceph start mon.node1
=== mon.node1 === 
Starting Ceph mon.node1 on node1...
Running as unit ceph-mon.node1.1494662569.716170251.service.
Starting ceph-create-keys on node1...
</pre>
#### 添加开机自启动
<pre>
chkconfig ceph on
</pre>
#### 验证 `mon` 节点
<pre>
[root@node1 ceph-node1]# ceph -s
    cluster e58bb0fd-0d89-4600-b2c2-27e1f58350cd
     health HEALTH_ERR
            64 pgs stuck inactive
            64 pgs stuck unclean
            no osds
     monmap e1: 1 mons at {node1=192.168.56.11:6789/0}
            election epoch 2, quorum 0 node1
     osdmap e1: 0 osds: 0 up, 0 in
      pgmap v2: 64 pgs, 1 pools, 0 bytes data, 0 objects
            0 kB used, 0 kB / 0 kB avail
                  64 creating
</pre>
健康状态显示为 `HEALTH_ERR` 等是因为还没有部署 `OSD`节点

### 加入 `OSDS`

部署好 `mon` 并运行后，必须拥有足够的 `OSDS`来处理对象的复制数(osd pool default size= =2需要最少两个OSDS)才能达到 `active+clean`的状态。在启动了 `monitor` 后，集群会有一个默认的 `CRUSH map`；然而，该`CRUSH map`没有任何指向到`ceph node`的`ceph osd`
#### 复制 `keyring` 文件及配置文件
<pre>
scp 192.168.56.11:/etc/ceph/ceph.client.admin.keyring /etc/ceph/
scp 192.168.56.11:/etc/ceph/ceph.conf /etc/ceph/
scp 192.168.56.11:/var/lib/ceph/bootstrap-osd/ceph.keyring /var/lib/ceph/bootstrap-osd/
</pre>
#### prepare OSD

<pre>
[root@node2 bootstrap-osd]# ceph-disk prepare --fs-type xfs /dev/sdb
The operation has completed successfully.
partx: /dev/sdb: error adding partition 2
The operation has completed successfully.
partx: /dev/sdb: error adding partitions 1-2
meta-data=/dev/sdb1              isize=2048   agcount=4, agsize=1245119 blks
         =                       sectsz=512   attr=2, projid32bit=1
         =                       crc=0        finobt=0
data     =                       bsize=4096   blocks=4980475, imaxpct=25
         =                       sunit=0      swidth=0 blks
naming   =version 2              bsize=4096   ascii-ci=0 ftype=0
log      =internal log           bsize=4096   blocks=2560, version=2
         =                       sectsz=512   sunit=0 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0
Warning: The kernel is still using the old partition table.
The new table will be used at the next reboot.
The operation has completed successfully.
partx: /dev/sdb: error adding partitions 1-2
[root@node2 bootstrap-osd]# parted /dev/sdb print
Model: VMware, VMware Virtual S (scsi)
Disk /dev/sdb: 21.5GB
Sector size (logical/physical): 512B/512B
Partition Table: gpt
Disk Flags: 

Number  Start   End     Size    File system  Name          Flags
 2      1049kB  1074MB  1073MB               ceph journal
 1      1075MB  21.5GB  20.4GB  xfs          ceph data
</pre>
### 激活`OSD`
<pre>
[root@node2 bootstrap-osd]# ceph-disk activate /dev/sdb
ceph-disk: Cannot discover filesystem type: device /dev/sdb: Line is truncated: 
[root@node2 bootstrap-osd]# ceph-disk activate /dev/sdb1
=== osd.0 === 
create-or-move updated item name 'osd.0' weight 0.02 at location {host=node2,root=default} to crush map
Starting Ceph osd.0 on node2...
Running as unit ceph-osd.0.1494767265.928813797.service.
[root@node3 ~]# ceph-disk activate /dev/sdb1
=== osd.1 === 
create-or-move updated item name 'osd.1' weight 0.02 at location {host=node3,root=default} to crush map
Starting Ceph osd.1 on node3...
Running as unit ceph-osd.1.1494767238.544066760.service.
</pre>
<pre>
[root@node2 bootstrap-osd]# ps -ef|grep ceph
root      2609     1  0 21:07 ?        00:00:00 /bin/bash -c ulimit -n 32768;  /usr/bin/ceph-osd -i 0 --pid-file /var/run/ceph/osd.0.pid -c /etc/ceph/ceph.conf --cluster ceph -f
root      2613  2609  0 21:07 ?        00:00:01 /usr/bin/ceph-osd -i 0 --pid-file /var/run/ceph/osd.0.pid -c /etc/ceph/ceph.conf --cluster ceph -f
</pre>
#### 服务启动关闭
<pre>
/etc/init.d/ceph stop
/etc/init.d/ceph start
chkconfig ceph on
</pre>
#### 设置自动挂载分区
<pre>
[root@node2 bootstrap-osd]# mount
/dev/sdb1 on /var/lib/ceph/osd/ceph-0 type xfs (rw,noatime,attr2,inode64,noquota)
echo /dev/sdb1 /var/lib/ceph/osd/ceph-0
echo 'UUID=246ba91d-cc1d-4516-b99b-fc52f3ea77bf /var/lib/ceph/osd/ceph-0      xfs     defaults        0 0' >> /etc/fstab
</pre>
ceph

已经学会了的
1. ceph的架构及能提供的服务种类
2. monitor和storage cluster两个集群
3. 搭建mon集群

还需要学习的
1. 搭建storage cluster
2. 增加节点及删除节点
3. 集成openstack

总结错误案例

当前系统状态(cluster map)和存储策略配置共同影响CRUSH算法的结果

### `Cluster map`

`Cluster Map`的实际内容包括：

1. Epoch，即版本号。Cluster map的epoch是一个单调递增序列。Epoch越大，则cluster map版本越新。因此，持有不同版本cluster map的OSD或client可以简单地通过比较epoch决定应该遵从谁手中的版本。而monitor手中必定有epoch最大、版本最新的cluster map。当任意两方在通信时发现彼此epoch值不同时，将默认先将cluster map同步至高版本一方的状态，再进行后续操作
2. 各个OSD的网络地址
3. 各个OSD的状态。OSD状态的描述分为两个维度：up或者down（表明OSD是否正常工作），in或者out（表明OSD是否在至少一个PG中）。因此，对于任意一个OSD，共有四种可能的状态
4. CRUSH算法配置参数。表明了Ceph集群的物理层级关系（cluster hierarchy），位置映射规则（placement rules）。


### 扩展 `MON` 节点
<pre>
[root@node4 yum.repos.d]# scp 192.168.56.11:/etc/ceph/ceph.conf /etc/ceph  
[root@node4 yum.repos.d]# scp 192.168.56.11:/etc/ceph/ceph.client.admin.keyring /etc/ceph
</pre>

#### 创建 `monitor` 默认数据目录
<pre>
mkdir /var/lib/ceph/mon/ceph-node4
</pre>

#### 取回显示器的 `keyring`
<pre>
[root@node4 mon]# ceph auth get mon. -o /etc/ceph/ceph.mon.keyring
exported keyring for mon.
[root@node4 ceph]# cat ceph.mon.keyring 
[mon.]
	key = AQBEtRZZb7/SBRAA3VtahK9IaRuTziwHCM1pVQ==
	caps mon = "allow *"
</pre>
#### 取回显示器的 `monitor map`
<pre>
root@node4 ceph]# ceph mon getmap -o /etc/ceph/monmap
got monmap epoch 1
[root@node4 ceph]# monmaptool --print monmap 
monmaptool: monmap file monmap
epoch 1
fsid e58bb0fd-0d89-4600-b2c2-27e1f58350cd
last_changed 2017-05-13 15:35:53.582619
created 2017-05-13 15:35:53.582619
0: 192.168.56.11:6789/0 mon.node1
</pre>
#### 将新的MON节点添加到monmap
<pre>
[root@node4 mon]# monmaptool --add node4 192.168.56.14 /etc/ceph/monmap 
monmaptool: monmap file /etc/ceph/monmap
monmaptool: writing epoch 1 to /etc/ceph/monmap (2 monitors)
[root@node4 mon]# monmaptool --print /etc/ceph/monmap 
monmaptool: monmap file /etc/ceph/monmap
epoch 1
fsid e58bb0fd-0d89-4600-b2c2-27e1f58350cd
last_changed 2017-05-13 15:35:53.582619
created 2017-05-13 15:35:53.582619
0: 192.168.56.11:6789/0 mon.node1
1: 192.168.56.14:6789/0 mon.node4
</pre>
#### 初始化MON数据目录
<pre>
[root@node4 ceph]# ceph-mon -i node4 --mkfs --monmap /etc/ceph/monmap --keyring /etc/ceph/ceph.mon.keyring 
ceph-mon: set fsid to e58bb0fd-0d89-4600-b2c2-27e1f58350cd
ceph-mon: created monfs at /var/lib/ceph/mon/ceph-node4 for mon.node4
</pre>
#### 将MON节点添加到集群
<pre>
[root@node4 mon]# ceph mon add node4 192.168.56.14
^CError connecting to cluster: InterruptedOrTimeoutError
</pre>
> 这一步应该可不操作
#### 完成MON节点初始化
<pre>
touch /var/lib/ceph/mon/ceph-node4/done
touch /var/lib/ceph/mon/ceph-node4/sysvinit
</pre>
#### 启动MON节点
<pre>
[root@node4 ceph-node4]# /etc/init.d/ceph start
=== mon.node4 === 
Starting Ceph mon.node4 on node4...
Running as unit ceph-mon.node4.1494841521.643855527.service.
Starting ceph-create-keys on node4...
</pre>
#### 设置开机自启动
<pre>
chkconfig ceph on
</pre>
#### 查看当前状态
<pre>
[root@node1 tmp]# ceph -s
    cluster e58bb0fd-0d89-4600-b2c2-27e1f58350cd
     health HEALTH_OK
     monmap e2: 2 mons at {node1=192.168.56.11:6789/0,node4=192.168.56.14:6789/0}
            election epoch 6, quorum 0,1 node1,node4
     osdmap e19: 2 osds: 2 up, 2 in
      pgmap v71: 64 pgs, 1 pools, 0 bytes data, 0 objects
            69804 kB used, 38821 MB / 38889 MB avail
                  64 active+clean
</pre>
#### 在`node2`节点上增加 `ceph-mon`
<pre>
[root@node2 ceph-node2]# ceph -s
    cluster e58bb0fd-0d89-4600-b2c2-27e1f58350cd
     health HEALTH_OK
     monmap e3: 3 mons at {node1=192.168.56.11:6789/0,node2=192.168.56.12:6789/0,node4=192.168.56.14:6789/0}
            election epoch 12, quorum 0,1,2 node1,node2,node4
     osdmap e29: 2 osds: 2 up, 2 in
      pgmap v88: 64 pgs, 1 pools, 0 bytes data, 0 objects
            68968 kB used, 38822 MB / 38889 MB avail
                  64 active+clean
</pre>

## 监控
<pre>
git clone https://github.com/thelan/ceph-zabbix.git
ceph-status.sh  README.md  zabbix_agent_ceph_plugin.conf  zabbix_templates
[root@node1 ceph-zabbix]# cp zabbix_agent_ceph_plugin.conf /etc/zabbix/zabbix_agentd.d/
[root@node1 ceph-zabbix]# cd /etc/zabbix/zabbix_agentd.d/
[root@node1 zabbix_agentd.d]# ls
userparameter_mysql.conf  zabbix_agent_ceph_plugin.conf
[root@node1 zabbix_agentd.d]# ll
total 8
-rw-r--r-- 1 root root 1531 Apr 24 02:11 userparameter_mysql.conf
-rw-r--r-- 1 root root 1704 May 15 18:31 zabbix_agent_ceph_plugin.conf
[root@node1 zabbix_agentd.d]# cp ~/ceph-zabbix/
ceph-status.sh                 README.md                      zabbix_templates/
.git/                          zabbix_agent_ceph_plugin.conf  
[root@node1 zabbix_agentd.d]# cp ~/ceph-zabbix/ceph-status.sh /opt/
</pre>
