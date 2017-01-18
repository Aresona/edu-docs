# OpenStack回顾

## 环境准备
在做这个架构前需要先确保下面两步

1. CPU支持虚拟化
<pre>
egrep -o '(vmx|svm)' /proc/cpuinfo
</pre>

2. 确保libvirt服务已经启动


## KVM
1. KVM是基于内核的虚拟机，也就是说KVM是基于内核实现的。
2. KVM有一个内核模块叫kvm.ko,只用于管理虚拟CPU和内存；IO的虚拟化，如存储和网络设备由 `linux`内核和 `qemu` 来管理
3. KVM是OpenStack使用最广泛的Hypervisor。
4. 一个KVM虚机在宿主机中其实是一个qemu-kvm进程，与其他linux进程一样被调度
5. 虚拟机中的每个虚拟vCPU对应qemu-kvm进程中的一个线程
6. 虚机的vCPU总数可以超过物理CPU数量，这个叫CPU overcommit。
7. KVM允许overcommit,这个特性使得虚机能够充分利用宿主机的CPU资源，但前提是在同一时刻，不是所有的虚机都满负荷运行。当然，如果每个虚机都很忙，反而会影响整体性能，所有在使用overcommit的时候，需要对虚机的负载情况有所了解，需要测试。

## 内存虚拟化
1. 为了在一台机器上运行多个虚拟机，KVM需要实现VA（虚拟内存） -> PA(物理内存) -> -MA（机器内存）间接的地址转换。虚机 OS 控制虚拟地址到客户内存物理地址的映射 （VA -> PA），但是虚机 OS 不能直接访问实际机器内存，因此 KVM 需要负责映射客户物理内存到实际机器内存 （PA -> MA）。具体的实现就不做过多介绍了，大家有兴趣可以查查资料。
2. 内存也是可以overcommit的，但使用时也需要测试，否则会影响性能。

## 存储虚拟化
1. KVM的存储虚拟化是通过存储池(storage Pool)和卷(Volume)来管理的
2. Storage Pool是宿主机上可以看到的一片存储空间，可以是多种类型
3. Volume是在`Storage Pool`中划出的一块空间，宿主机将Volume分配给虚拟机，Volume在虚拟机中看到的就是一块硬盘。

### 不同的Storage Pool
KVM还支持iSCSI,Ceph等多种类型的Storage Pool，但最常用的就是目录类型。

#### 文件目录

1. 文件目录是最常用的Storage Pool类型,这种情况下Volume就是这个目录下的文件，一个文件就是一个volume
2. 默认在`/etc/libvirt/storage`目录下有不同的xml文件，每个xml文件就代表一个pool,而default.xml定义了默认的pool
3. 使用文件做volume有很多优点：存储方便、移值性好、可复制、可远程访问；远程访问的意思是镜像文件不一定放置在宿主机本地文件系统中，也可以存储在通过网络连接的远程文件系统，如NFS、GlusterFS等
4. 镜像文件的共享可以方便虚机在不同宿主机之间做live Migration。
5. raw是默认磁盘格式，即原始磁盘镜像格式，移植性好，性能好，但是大小固定，不能节省磁盘空间
6. qcow2是推荐使用的格式，cow表示copy on write,能够节省磁盘空间，支持AES加密，支持zlib压缩，支持多快照，功能很多。
7. vmdk是VMware的虚拟磁盘格式，也就是说VMware虚机可以直接在KVM上运行。

#### LVM

不仅一个文件可以分配给客户机作为虚拟磁盘，宿主机上VG中的LV也可以作为虚拟磁盘分配给虚拟机使用。**不过LV由于没有磁盘MBR引导记录，不能作为虚拟机的启动盘，只能作为数据盘使用**

1. VG就是一个Storage Pool,VG中的LV就是Volume
2. 可以通过virsh命令定义一个存储池，如下
<pre>
virsh pool-define /etc/libvirt/storage/HostVG.xml
virsh pool-start HostVG
</pre>

## 网络虚拟化
### linux bridge
1. linux Bridge是linux上用来做TCP/IP二层协议交换的设备，多个网络设备可以连接到同一个Linux Bridge,当某个设备收到数据包时，Linux Bridge会将数据转发给其他设备，这样就实现了双向通信
2. 物理IP地址可以直接配置在br设备上，这时真实物理网卡需要通过配置文件来连接到这块设备上(bridge\_ports eth0)
3. vnet0或者下面的tapf324bbcc-55是该虚拟网卡在宿主机中对应的设备名称，其类型是TAP设备。
4. virbr0是KVM默认创建的一个Bridge,其作用是为连接其上的虚机网卡提供NAT访问外网的功能
5. virbr0使用dnsmasq提供DHCP服务，可以在宿主机中查看到该进程的信息
6. LAN表示Local Area Network,本地局域网，通常使用Hub和Switch来连接LAN中的计算机，一般来说，两台计算机连入同一个Hub或者Switch时，它们就在同一个LAN中，也就是说LAN中的所有成员都会收到任意一个成员发出的**广播包**。（arp属于广播包）
7. VLAN表示Virtual LAN,一个带有VLAN功能的switch能够将自己的端口划分出多个LAN，计算机发出的广播包可以被同一个LAN中的其他计算机收到，但位于其他LAN的计算机则无法收到
8. 请注意，VLAN 的隔离是二层上的隔离，A 和 B 无法相互访问指的是二层广播包（比如 arp）无法跨越 VLAN 的边界。但在三层上（比如IP）是可以通过路由器让 A 和 B 互通的。概念上一定要分清。
9. 交换机的端口有两种类型，access口都是直接与计算机相连的，这样从该网卡出来的数据包注入Access口后就被打上了所在VLAN的标签，Access只能属于一个VLAN
10. Trunk口用来连接不同的交换机，数据包在通过该口到达对方交换机的过程中始终带着自己的VLAN标签。

**KVM虚拟化环境下如何实现VLAN**
![](http://7xo6kd.com1.z0.glb.clouddn.com/upload-ueditor-image-20160324-1458779560717052345.jpg?_=5313994)

eth0 是宿主机上的物理网卡，有一个命名为 `eth0.10` 的子设备与之相连。
`eth0.10` 就是 VLAN 设备了，其 VLAN ID 就是 VLAN 10。
`eth0.10` 挂在命名为 `brvlan10` 的 Linux Bridge 上，虚机 VM1 的虚拟网卡 `vent0` 也挂在 `brvlan10` 上。

查看VM的虚拟网卡
<pre>
[root@openstack-slave1 storage]# virsh domiflist instance-0000009c
Interface  Type       Source     Model       MAC
-------------------------------------------------------
tapf324bbcc-55 bridge     brq4fee3df9-c6 virtio      fa:16:3e:cd:ed:36
</pre>

## Libvirt

1. Libvirt是KVM的管理工具，它还可以管理Xen,VirtualBox等。
2. Libvirt包含3个东西：后台程序`livirtd`,`API库`和命令行工具 `virsh`
3. API库使得其他人可以开发基于Libvirt的高级工具，比如virt-manager
4. 作为KVM和OpenStack的实施人员，virsh和virt-manager是一定要会用的。

## virt-manager

1. virt-manager也可以管理其他宿主机上的虚机，只需要将宿主机添加进来就可以了
2. libvirt默认不接受远程管理，需要管理两个配置文件： `/etc/default/libvirt-bin`、`/etc/libvirt/libvirtd.conf`
3. 

## Ubuntu下安装图形界面

<pre>
apt-get install xinit gdm kubuntu-desktop -y
</pre>


## 云计算基本概念

计算（CPU/内存）、存储和网络是 IT 系统的三类资源。通过云计算平台，这三类资源变成了三个池子。

当需要虚机的时候，只需要向平台提供虚机的规格。平台会快速从三个资源池分配相应的资源，部署出这样一个满足规格的虚机。

云平台是一个面向服务的架构，按照提供服务的不同分为IaaS、PaaS和SaaS。

![](http://img.blog.csdn.net/20160329205344575)

**IaaS**（Infrastructure as a Service）提供的服务是虚拟机。
IaaS 负责管理虚机的生命周期，包括创建、修改、备份、启停、销毁等。
使用者从云平台得到的是一个已经安装好镜像（操作系统+其他预装软件）的虚拟机。
使用者需要关心虚机的类型（OS）和配置（CPU、内存、磁盘），并且自己负责部署上层的中间件和应用。
IaaS 的使用者通常是数据中心的系统管理员。
典型的 IaaS 例子有 AWS、Rackspace、阿里云等

**PaaS**（Platform as a Service）提供的服务是应用的运行环境和一系列中间件服务（比如数据库、消息队列等）。
使用者只需专注应用的开发，并将自己的应用和数据部署到PaaS环境中。
PaaS负责保证这些服务的可用性和性能。
PaaS的使用者通常是应用的开发人员。
典型的 PaaS 有 Google App Engine、IBM BlueMix 等

**SaaS**（Software as a Service）提供的是应用服务。
使用者只需要登录并使用应用，无需关心应用使用什么技术实现，也不需要关系应用部署在哪里。
SaaS的使用者通常是应用的最终用户。
典型的 SaaS 有 Google Gmail、Salesforce 等

> OpenStack is a cloud operating system that controls large pools of compute, storage, and networking resources throughout a datacenter, all managed through a dashboard that gives administrators control while empowering their users to provision resources through a web interface.

由此可见，OpenStack 针对的是 IT 基础设施，是 IaaS 这个层次的云操作系统。

# 部署

部署其实非常灵活，但学习时我们可以按各种分类来分析哪些服务应该装在哪些地方，如下：

OpenStack 是一个分布式系统，由若干不同功能的节点（Node）组成：

* 控制节点（Controller Node）

管理 OpenStack，其上运行的服务有 Keystone、Glance、Horizon 以及 Nova 和 Neutron 中管理相关的组件。
控制节点也运行支持 OpenStack 的服务，例如 SQL 数据库（通常是 MySQL）、消息队列（通常是 RabbitMQ）和网络时间服务 NTP。        

* 网络节点（Network Node）

其上运行的服务为 Neutron。
为 OpenStack 提供 L2 和 L3 网络。
包括虚拟机网络、DHCP、路由、NAT 等。        

* 存储节点（Storage Node）

提供块存储（Cinder）或对象存储（Swift）服务。        

* 计算节点（Compute Node）

其上运行 Hypervisor（默认使用 KVM）。
同时运行 Neutron 服务的 agent，为虚拟机提供网络支持。        

这几类节点是从功能上进行的逻辑划分，在实际部署时可以根据需求灵活配置，比如：

在大规模OpenStack生产环境中，每类节点都分别部署在若干台物理服务器上，各司其职并互相协作。 
这样的环境具备很好的性能、伸缩性和高可用性。

在最小的实验环境中，可以将 4 类节点部署到一个物理的甚至是虚拟服务器上。 
麻雀虽小五脏俱全，通常也称为 All-in-One 部署。

在我们的实验环境中，为了使得拓扑简洁同时功能完备，我们用两个虚拟机：

devstack-controller：控制节点 + 网络节点 + 块存储节点 + 计算节点

devstack-compute：计算节点

## 常见服务类型

![](http://7xo6kd.com1.z0.glb.clouddn.com/upload-ueditor-image-20160404-1459724662268078986.png?_=5350536)

* Management Network: 用于OpenStack内部管理用，比如各服务之间通信。这里使用eth0
* VM（Tenant）Network：OpenStack 部署的虚拟机所使用的网络。OpenStack 支持多租户（Tenant），虚机是放在 Tenant 下的，所以叫 Tenant Network。这里使用 eth1 
* External Network：一般来说，Tenant Network 是内部私有网络，只用于 VM 之间通信，与其他非 VM 网络是隔离的。这里我们规划了一个外部网络（External Network），通过 devstak-controller 的 eth2 连接。


Neutron 通过 L3 服务让 VM 能够访问到 External Network。
对于公有云，External Network 一般指的是 Internet。
对于企业私有云，External Network 则可以是 Intranet 中的某个网络。  


# 常用服务架构

整体架构之 `Conceptual Architecture`

![](http://7xo6kd.com1.z0.glb.clouddn.com/upload-ueditor-image-20160331-1459396288164018195.jpg?_=5340622)

整体架构之 `logical Architecture`

![](http://7xo6kd.com1.z0.glb.clouddn.com/upload-ueditor-image-20160331-1459396289980075632.jpg?_=5340622)

## Neutron

![](http://7xo6kd.com1.z0.glb.clouddn.com/upload-ueditor-image-20160331-1459396290319030381.jpg?_=5340622)


## [Keystone](http://www.cnblogs.com/CloudMan6/p/5365474.html)

主要功能：

1. 管理用户及权限
2. 维护 `OpenStack Services` 的 `Endpoint`
3. `Authentication` (认证)和 `Authorization` (鉴权)

相关概念

![](http://7xo6kd.com1.z0.glb.clouddn.com/upload-ueditor-image-20160407-1460033914633035973.jpg?_=5365474)

**User**

1. User 指代任何使用 OpenStack 的实体，可以是真正的用户，其他系统或者服务。
2. 除了 admin 和 demo，OpenStack 也为 nova、cinder、glance、neutron 服务创建了相应的 User。 admin 也可以管理这些 User。

**Credentials(资格)**

Credentials 是 User 用来证明自己身份的信息，可以是： 

1. 用户名/密码
2. Token 
3. API Key
4. 其他高级方式

**Authentication(身份认证)**

Authentication 是 Keystone 验证 User 身份的过程。

User 访问 OpenStack 时向 Keystone 提交用户名和密码形式的 Credentials，Keystone 验证通过后会给 User 签发一个 Token 作为后续访问的 Credential。

**Token**

`Token` 是由数字和字母组成的字符串，`User` 成功 `Authentication` 后由 `Keystone` 分配给 `User`。

1. Token 用做访问 Service 的 Credential
2. Service 会通过 Keystone 验证 Token 的有效性
3. Token 的有效期默认是 24 小时

**Project**

Project 用于将 OpenStack 的资源（计算、存储和网络）进行分组和隔离。 根据 OpenStack 服务的对象不同，Project 可以是一个客户（公有云，也叫租户）、部门或者项目组（私有云）。

这里请注意：

1. 资源的所有权是属于 Project 的，而不是 User。
2. 在 OpenStack 的界面和文档中，Tenant / Project / Account 这几个术语是通用的，但长期看会倾向使用 Project
3. 每个 User（包括 admin）必须挂在 Project 里才能访问该 Project 的资源。 一个User可以属于多个 Project。
4. admin 相当于 root 用户，具有最高权限


**Service**

OpenStack 的 Service 包括 Compute (Nova)、Block Storage (Cinder)、Object Storage (Swift)、Image Service (Glance) 、Networking Service (Neutron) 等。

每个 Service 都会提供若干个 Endpoint，User 通过 Endpoint 访问资源和执行操作。

**Endpoint**

Endpoint 是一个网络上可访问的地址，通常是一个 URL。 Service 通过 Endpoint 暴露自己的 API。 Keystone 负责管理和维护每个 Service 的 Endpoint。

<pre>
openstack catalog list
</pre>


**Role**

安全包含两部分：Authentication（认证）和 Authorization（鉴权） Authentication 解决的是“你是谁？”的问题 Authorization 解决的是“你能干什么？”的问题

Keystone 是借助 Role 来实现 Authorization 的：

1. Keystone 定义Role
2. 可以为 User 分配一个或多个 Role. Horizon 的菜单为 Identity->Project->Manage Members
3. Service 决定每个 Role 能做什么事情 Service 通过各自的 policy.json 文件对 Role 进行访问控制。
4. OpenStack 默认配置只区分 admin 和非 admin Role。 如果需要对特定的 Role 进行授权，可以修改 policy.json。


## [Glance](http://www.cnblogs.com/CloudMan6/p/5384923.html)

### 架构

![](http://7xo6kd.com1.z0.glb.clouddn.com/upload-ueditor-image-20160412-1460472066871043421.jpg?_=5384923)

### Glance-api

glance-api 是系统后台运行的服务进程。对外提供 REST API，响应 image 查询、获取和存储的调用。

glance-api 不会真正处理请求。如果是与 image metadata（元数据）相关的操作，glance-api 会把请求转发给 glance-registry；

如果是与 image 自身存取相关的操作，glance-api 会把请求转发给该 image 的 store backend。

### Glance-registry

glance-registry 是系统后台运行的服务进程。
负责处理和存取 image 的 metadata，例如 image 的大小和类型。

### Store backend

Glance 自己并不存储 image。真正的 image 是存放在 backend 中的。Glance 支持多种 backend，包括:

* A directory on a local file system（这是默认配置）
* GridFS
* Ceph RBD
* Amazon S3
* Sheepdog
* OpenStack Block Storage (Cinder)
* OpenStack Object Storage (Swift)
* VMware ESX

具体使用哪种 backend，是在 `/etc/glance/glance-api.conf` 中配置的

## Nova

![](http://7xo6kd.com1.z0.glb.clouddn.com/upload-ueditor-image-20160419-1461074078681029733.png?_=5410447)

Nova 的架构比较复杂，包含很多组件。 
这些组件以子服务（后台 deamon 进程）的形式运行，可以分为以下几类：

### API

**nova-api**

接收和响应客户的API调用

Nova-api 对接收到的 HTTP API 请求会做如下处理：

1.	检查客户端传人的参数是否合法有效
2.	调用 Nova 其他子服务的处理客户端 HTTP 请求
3.	格式化 Nova 其他子服务返回的结果并返回给客户端

### Compte Core

[**nova-scheduler**](http://www.cnblogs.com/CloudMan6/p/5441782.html)

虚机调度服务，负责决定在哪个计算节点上运行虚机

<pre>scheduler_driver=nova.scheduler.filter_scheduler.FilterScheduler
scheduler_available_filters = nova.scheduler.filters.all_filters
scheduler_default_filters = RetryFilter, AvailabilityZoneFilter, RamFilter, DiskFilter, ComputeFilter, ComputeCapabilitiesFilter, ImagePropertiesFilter, ServerGroupAntiAffinityFilter, ServerGroupAffinityFilter
</pre>

1. Nova 允许使用第三方 scheduler，配置 scheduler_driver 即可
2. Nova.conf 中的 scheduler_available_filters 选项用于配置 scheduler 可用的 filter，默认是所有 nova 自带的 filter 都可以用于滤操作
3. 另外还有一个选项 scheduler_default_filters，用于指定 scheduler 真正使用的 filter.Filter scheduler 将按照列表中的顺序依次过滤。

> ServerGroupAntiAffinityFilter和ServerGroupAffinityFilter的使用原理是先创建指定类型的组，在创建虚拟机的时候选定相应的组，那么这个组里面的虚机就会都集中一台计算节点上或者

<pre>
ram_allocation_ratio = 1.5
disk_allocation_ratio = 1.0
cpu_allocation_ratio = 16.0
</pre>

前面都是**FILET**的内容，而对于**Weight**来说，目前默认的计算得分方法是根据计算节点空闲的内在量计算值。


**Metadata**

Metadata在ImagePropertiesFilter和ComputeCapabilitiesFilter过滤的时候都会用到，它们的属性分别在flavor和image里面设置。

**nova-compute**

管理虚机的核心服务，通过调用 Hypervisor API 实现虚机生命周期管理

**Hypervisor**

计算节点上跑的虚拟化管理程序，虚机管理最底层的程序。
不同虚拟化技术提供自己的 Hypervisor。
常用的 Hypervisor 有 KVM，Xen， VMWare 等

**nova-conductor**

nova-compute 经常需要更新数据库，比如更新虚机的状态。
出于安全性和伸缩性的考虑，nova-compute 并不会直接访问数据库，而是将这个任务委托给 nova-conductor，这个我们在后面会详细讨论。

这样做有两个显著好处：

1. 更高的系统安全性
2. 更好的系统伸缩性

nova-conductor 将 nova-compute 与数据库解耦之后还带来另一个好处：提高了 nova 的伸缩性。

nova-compute 与 conductor 是通过消息中间件交互的。
这种松散的架构允许配置多个 nova-conductor 实例。
在一个大规模的 OpenStack 部署环境里，管理员可以通过增加 nova-conductor 的数量来应对日益增长的计算节点对数据库的访问。

### Console Interface

**nova-console**

用户可以通过多种方式访问虚机的控制台：

* nova-novncproxy，基于 Web 浏览器的 VNC 访问
* nova-spicehtml5proxy，基于 HTML5 浏览器的 SPICE 访问
* nova-xvpnvncproxy，基于 Java 客户端的 VNC 访问

**nova-consoleauth**

负责对访问虚机控制台请求提供 Token 认证

**nova-cert**

提供x509证书支持

### Message Queue

Nova包含众多的子服务，这些子服务之间需要相互协调和通信。为解耦各个子服务，Nova通过Message Queue作为子服务的信息中转站。

高级消息队列协议（AMQP1），它是一种协议，而rabbitmq是AMQP服务器

### 从虚机创建流程看nova-*子服务如何协同工作

![](http://www.cnblogs.com/CloudMan6/p/5415836.html)

1. 客户（可以是 OpenStack 最终用户，也可以是其他程序）向 API（nova-api）发送请求：“帮我创建一个虚机”
2. API 对请求做一些必要处理后，向 Messaging（RabbitMQ）发送了一条消息：“让 Scheduler 创建一个虚机”
3. Scheduler（nova-scheduler）从 Messaging 获取到 API 发给它的消息，然后执行调度算法，从若干计算节点中选出节点 A
4. Scheduler 向 Messaging 发送了一条消息：“在计算节点 A 上创建这个虚机”
5. 计算节点 A 的 Compute（nova-compute）从 Messaging 中获取到 Scheduler 发给它的消息，然后在本节点的 Hypervisor 上启动虚机。
6. 在虚机创建的过程中，Compute 如果需要查询或更新数据库信息，会通过 Messaging 向 Conductor（nova-conductor）发送消息，Conductor 负责数据库访问。

# Tips

## OpenStack命令命名

OpenStack 服务都有自己的 CLI。
命令很好记，就是服务的名字，比如 Glance 就是 glance，Nova 就是 nova。

但 Keystone 比较特殊，现在是用 openstack 来代替老版的 keystone 命令。
比如查询用户列表，如果用 keystone user-list

不同服务用的命令虽然不同，但这些命令使用方式却非常类似，可以举一反三。

1. 执行命令前，需要设置环境变量 
2. 各个服务的命令都有增、删、改、查的操作
3. 每个对象都有ID
4. 可用help查看命令的用法(glance help、glance help image-update)

## [OpenStack 组件的通用设计思路](http://www.cnblogs.com/CloudMan6/p/5427981.html)

### API前端服务

每个 OpenStack 组件可能包含若干子服务，其中必定有一个 API 服务负责接收客户请求。 

以 Nova 为例，nova-api 作为 Nova 组件对外的唯一窗口，向客户暴露 Nova 能够提供的功能。 当客户需要执行虚机相关的操作，能且只能向 nova-api 发送 REST 请求。 这里的客户包括终端用户、命令行和 OpenStack 其他组件。 

设计 API 前端服务的好处在于： 

1. 对外提供统一接口，隐藏实现细节 
2. API 提供 REST 标准调用服务，便于与第三方系统集成 
3. 可以通过运行多个 API 服务实例轻松实现 API 的高可用，比如运行多个 nova-api 进程 

### Scheduler 调度服务

对于某项操作，如果有多个实体都能够完成任务，那么通常会有一个 scheduler 负责从这些实体中挑选出一个最合适的来执行操作。 

在前面的例子中，Nova 有多个计算节点。 当需要创建虚机时，nova-scheduler 会根据计算节点当时的资源使用情况选择一个最合适的计算节点来运行虚机。 

调度服务就好比是一个开发团队中的项目经理，当接到新的开发任务时，项目经理会评估任务的难度，考察团队成员目前的工作负荷和技能水平，然后将任务分配给最合适的开发人员。 

除了 Nova，块服务组件 Cinder 也有 scheduler 子服务，后面我们会详细讨论。 

### Worker 工作服务

调度服务只管分配任务，真正执行任务的是 Worker 工作服务。 

在 Nova 中，这个 Worker 就是 nova-compute 了。 将 Scheduler 和 Worker 从职能上进行划分使得 OpenStack 非常容易扩展： 

1. 当计算资源不够了无法创建虚机时，可以增加计算节点（增加 Worker）
2. 当客户的请求量太大调度不过来时，可以增加 Scheduler

### Driver 框架

OpenStack 作为开放的 Infrastracture as a Service 云操作系统，支持业界各种优秀的技术。 这些技术可能是开源免费的，也可能是商业收费的。 这种开放的架构使得 OpenStack 能够在技术上保持先进性，具有很强的竞争力，同时又不会造成厂商锁定（Lock-in）。 

那 OpenStack 的这种开放性体现在哪里呢？ 一个重要的方面就是采用基于 Driver 的框架。 

以 Nova 为例，OpenStack 的计算节点支持多种 Hypervisor。 包括 KVM, Hyper-V, VMWare, Xen, Docker, LXC 等。 

Nova-compute 为这些 Hypervisor 定义了统一的接口，hypervisor 只需要实现这些接口，就可以 driver 的形式即插即用到 OpenStack 中。 下面是 nova driver 的架构示意图 

![](http://7xo6kd.com1.z0.glb.clouddn.com/upload-ueditor-image-20160424-1461498587439070722.jpg?_=5427981)

### Messaging 服务

程序之间的调用通常分两种：同步调用和异步调用。

**同步调用**

API 直接调用 Scheduler 的接口就是同步调用。其特点是 API 发出请求后需要一直等待，直到 Scheduler 完成对 Compute 的调度，将结果返回给 API 后 API 才能够继续做后面的工作。

**异步调用**

API 通过 Messaging 间接调用 Scheduler 就是异步调用。
其特点是 API 发出请求后不需要等待，直接返回，继续做后面的工作。

Scheduler 从 Messaging 接收到请求后执行调度操作，完成后将结果也通过 Messaging 发送给 API。

在 OpenStack 这类分布式系统中，通常采用异步调用的方式，其好处是：

1. **解耦各子服务**  子服务不需要知道其他服务在哪里运行，只需要发送消息给 Messaging 就能完成调用。
2. **提高性能**
异步调用使得调用者无需等待结果返回。这样可以继续执行更多的工作，提高系统总的吞吐量。
3. **提高伸缩性**
子服务可以根据需要进行扩展，启动更多的实例处理更多的请求，在提高可用性的同时也提高了整个系统的伸缩性。而且这种变化不会影响到其他子服务，也就是说变化对别人是透明的。

