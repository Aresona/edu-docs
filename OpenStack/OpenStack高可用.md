# [OpenStack高可用](http://www.cnblogs.com/sammyliu/p/4741967.html)

## 基础知识

### 高可用(HA)
高可用性是指提供在本地系统单个组件故障情况下，能继续访问应用的能力，无论这个故障是业务流程、物理设施、IT软/硬件的故障。最好的可用性， 就是你的一台机器宕机了，但是使用你的服务的用户完全感觉不到。你的机器宕机了，在该机器上运行的服务肯定得做故障切换（failover），切换有两个维度的成本：RTO （Recovery Time Objective）和 RPO（Recovery Point Objective）。RTO 是服务恢复的时间，最佳的情况是 0，这意味着服务立即恢复；最坏是无穷大意味着服务永远恢复不了；RPO 是切换时向前恢复的数据的时间长度，0 意味着使用同步的数据，大于 0 意味着有数据丢失，比如 ” RPO = 1 天“ 意味着恢复时使用一天前的数据，那么一天之内的数据就丢失了。因此，恢复的最佳结果是 RTO = RPO = 0，但是这个太理想，或者要实现的话成本太高，全球估计 Visa 等少数几个公司能实现，或者几乎实现。

对 HA 来说，往往使用共享存储，这样的话，RPO =0 ；同时往往使用 Active/Active （双活集群） HA 模式来使得 RTO 几乎0，如果使用 Active/Passive 模式的 HA 的话，则需要将 RTO 减少到最小限度。HA 的计算公式是[ 1 - (宕机时间)/（宕机时间 + 运行时间）]，我们常常用几个 9 表示可用性：

* 2 个9：99% = 1% * 365 = 3.65 * 24 小时/年 = 87.6 小时/年的宕机时间
* 4 个9: 99.99% = 0.01% * 365 * 24 * 60 = 52.56 分钟/年
* 5 个9：99.999% = 0.001% * 365 = 5.265 分钟/年的宕机时间，也就意味着每次停机时间在一到两分钟。
* 11 个 9：几乎就是几年才宕机几分钟。 据说 AWS S3 的设计高可用性就是 11 个 9。

#### 服务的分类

HA将服务分为两类：

- 有状态服务： 后续对服务的请求依赖于之前对服务的请求。
- 无状态服务： 对服务的请求之间没有依赖关系，是完全独立的。

#### HA的种类

HA需要使用冗余的服务器组成集群来运行负载，包括应用和服务。这种冗余也可以将HA分为两类：

- **Active/Passive HA:** 集群只包括两个节点简称主备。在这种配置下，系统采用主和备用机器来提供服务，系统只在主设备上提供服务。在主设备故障时，备设备上的服务被启动来替代主设备提供的服务。典型地，可以采用 CRM(Cluster Resource Manager)软件比如 Pacemaker 来控制主备设备之间的切换，并提供一个虚机 IP 来提供服务。
- **Active/Active HA:** 集群只包括两个节点时简称双活，包括多节点时成为多主（Multi-master）。在这种配置下，系统在集群内所有服务器上运行同样的负载。以数据库为例，对一个实例的更新，会被同步到所有实例上。这种配置下往往采用负载均衡软件比如 HAProxy 来提供服务的虚拟 IP。

> [pacemaker](http://freeloda.blog.51cto.com/2033581/1274533) 是个资源管理器，不是提供心跳信息的，因为它似乎是一个普遍的误解，也是值得的。pacemaker是一个延续的CRM（亦称Heartbeat V2资源管理器），最初是为心跳，但已经成为独立的项目。

#### 云环境的HA

云环境包括一个广泛的系统，包括硬件基础设施、IaaS层、虚机和应用。以 `OpenStack` 云为例：

![](http://i.imgur.com/sC1nJn5.jpg)

云环境的HA包括：

- 应用的HA
- 虚机的HA
- 云控制服务的HA
- 物理IT层： 包括网络设备比如交换机和路由器，存储设备等
- 基础设施，比如电力、空调和防火设施等

本文重点讨论 `OpenStack` 作为 `IaaS` 的 `HA`

### 灾难恢复(Disaster Recovery)

几个概念：

- 灾难（Disaster）是由于人为或自然的原因，造成一个数据中心内的信息系统运行严重故障或瘫痪，使信息系统支持的业务功能停顿或服务水平不可接受、达到特定的时间的突发性事件，通常导致信息系统需要切换到备用场地运行。
- 灾难恢复（Diaster Recovery）是指当灾难破坏生产中心时在不同地点的数据中心内恢复数据、应用或者业务的能力。
容灾是指，除了生产站点以外，用户另外建立的冗余站点，当灾难发生，生产站点受到破坏时，冗余站点可以接管用户正常的业务，达到业务不间断的目的。为了达到更高的可用性，许多用户甚至建立多个冗余站点。 
- 衡量容灾系统有两个主要指标：RPO（Recovery Point Objective）和 RTO（Recovery Time Object），其中 RPO代表 了当灾难发生时允许丢失的数据量，而 RTO 则代表了系统恢复的时间。RPO 与 RTO 越小，系统的可用性就越高，当然用户需要的投资也越大。

![](http://i.imgur.com/6Se0bhC.jpg)

大体上讲，容灾可以分为3个级别：数据级别、应用级别以及业务级别。

级别   | 	定义|	RTO|	CTO
--- |
数据级   |  指通过建立异地容灾中心，做数据的远程备份，在灾难发生之后要确保原有的数据不会丢失或者遭到破坏。  但在数据级容灾这个级别，发生灾难时应用是会中断的。在数据级容灾方式下，所建立的异地容灾中心可以简单地把它理解成一个远程的数据备份中心。数据级容灾的恢复时间比较长，但是相比其他容灾级别来讲它的费用比较低，而且构建实施也相对简单。 但是，“数据源是一切关键性业务系统的生命源泉”，因此数据级容灾必不可少。 | RTO 最长(若干天) ，因为灾难发生时，需要重新部署机器，利用备份数据恢复业务。 |	最低
应用级 | 在数据级容灾的基础之上，在备份站点同样构建一套相同的应用系统，通过同步或异步复制技术，这样可以保证关键应用在允许的时间范围内恢复运行，尽可能减少灾难带来的损失，让用户基本感受不到灾难的发生，这样就使系统所提供的服务是完整的、可靠的和安全的。 |RTO 中等（若干小时）| 中等。异地可以搭建一样的系统，或者小些的系统
业务级|	全业务的灾备，除了必要的 IT 相关技术，还要求具备全部的基础设施。其大部分内容是非IT系统（如电话、办公地点等），当大灾难发生后，原有的办公场所都会受到破坏，除了数据和应用的恢复，更需要一个备份的工作场所能够正常的开展业务。	| RTO 最小（若干分钟或者秒）	|最高

### HA和DR的关系

两者相互关联，互相补充，互有交叉，同时又有显著的区别：

- **HA：** 往往指本地的高可用系统，表示在多个服务器运行一个或多种应用的情况下，应确保任意服务器出现任何故障时，其运行的应用不能中断，应用程序和系统应能迅速切换到其它服务器上运行，即本地系统集群和热备份。HA 往往是用共享存储，因此往往不会有数据丢失（RPO = 0），更多的是切换时间长度考虑即 RTO。
- **DR：** 是指异地（同城或者异地）的高可用系统，表示在灾害发生时，数据、应用以及业务的恢复能力。异地灾备的数据灾备部分是使用数据复制，根据使用的不同数据复制技术（同步、异步、Strectched Cluster 等），数据往往有损失导致 RPO >0；而异地的应用切换往往需要更长的时间，这样 RT0 >0。 因此，需要结合特定的业务需求，来定制所需要的 RTO 和 RPO，以实现最优的 CTO。

也可以从别的角度上看待两者的区别：

- 从故障角度，HA主要处理单组件的故障导致负载在集群内的服务器之间的切换，DR则是应对大规模的故障导致负载在数据中心之间做切换。
- 从网络角度，LAN尺度的任务是HA的范畴，WAN尺度的任务是DR的范围。
- 从云的角度看，HA是一个云环境内保障业务持续性的机制，DR是多个云环境间保障业务持续性的机制。
- 从目标角度，HA主要是保证业务高可用，DR是做主数据可靠的基础上的业务可用。


一个异地容灾系统，往往包括本地的HA集群和异地的DR数据中心。一个示例如下：

![](http://i.imgur.com/yntuPsw.jpg)

Master SQL Server 发生故障时，切换到 Standby SQL Server，继续提供数据库服务：

![](http://i.imgur.com/UzwpoEv.jpg)

在主机房中心发生灾难时，切换到备份机房（总公司机房中心）上，恢复应用和服务：

![](http://i.imgur.com/MjFmAdk.jpg)

## OpenStack HA

OpenStack 部署环境中，各节点可以分为几类：

- Cloud Controller Node （云控制节点）：安装各种 API 服务和内部工作组件（worker process）。同时，往往将共享的 DB 和 MQ 安装在该节点上。
- Neutron Controller Node （网络控制节点）：安装 Neutron L3 Agent，L2 Agent，LBaas，VPNaas，FWaas，Metadata Agent 等 Neutron 组件。
- Storage Controller Node （存储控制节点）：安装 Cinder volume 以及 Swift 组件。
- Compute node （计算节点）：安装 Nova-compute 和 Neutron L2 Agent，在该节点上创建虚机。


要实现 OpenStack HA，一个最基本的要求是这些节点都是冗余的。根据每个节点上部署的软件特点和要求，每个节点可以采用不同的 HA 模式。但是，选择 HA 模式有个基本的原则：

- 能 A/A 尽量 A/A，不能的话则 A/P （RedHat 认为 A/P HA 是 No HA）
- 有原生（内在实现的）HA方案尽量选用原生方案，没有的话则使用额外的HA 软件比如 Pacemaker 等
- 需要考虑负载均衡
- 方案尽可能简单，不要太复杂

OpenStack 官方认为，在满足其 HA 要求的情况下，可以实现 IaaS 的 99.99% HA，但是，这不包括单个客户机的 HA。

### 云控制节点HA

云控制节点上运行的服务中，API 服务和内部工作组件都是无状态的，因此很容易就可以实现 A/A HA；这样就要求 Mysql 和 RabbitMQ 也实现 A/A HA，而它们各自都有 A/A 方案。但是，Mysql Gelera 方案要求三台服务器。如果只想用两台服务器的话，则只能实现 A/P HA，或者引入一个 Arbiter 来做 A/A HA。

#### 云控制节点的A/A HA方案

该方案至少需要三台服务器。以 RDO 提供的案例为例，它由三台机器搭建成一个 Pacemaker A/A集群，在该集群的每个节点上运行：

- API 服务：包括 *-api, neutron-server，glance-registry, nova-novncproxy，keystone，httpd 等。由 HAProxy 提供负载均衡，将请求按照一定的算法转到某个节点上的 API 服务。由  Pacemaker 提供 VIP。
- 内部组件：包括 *-scheduler，nova-conductor，nova-cert 等。它们都是无状态的，因此可以在多个节点上部署，它们会使用 HA 的 MQ 和 DB。
- RabbitMQ：跨三个节点部署 RabbitMQ 集群和镜像消息队列。可以使用 HAProxy 提供负载均衡，或者将 RabbitMQ host list 配置给 OpenStack 组件（使用 rabbit_hosts 和 rabbit_ha_queues 配置项）。
- MariaDB：跨三个阶段部署 Gelera MariaDB 多主复制集群。由 HAProxy 提供负载均衡。
- HAProxy：向 API，RabbitMQ 和 MariaDB 多活服务提供负载均衡，其自身由 Pacemaker 实现 A/P HA，提供 VIP，某一时刻只由一个HAProxy提供服务。在部署中，也可以部署单独的 HAProxy 集群。
- Memcached：它原生支持 A/A，只需要在 OpenStack 中配置它所有节点的名称即可，比如，`memcached_servers = controller1:11211,controller2:11211`。当 `controller1:11211` 失效时，OpenStack 组件会自动使用`controller2:11211`。 


![](http://i.imgur.com/6AFd6mm.jpg)

从每个API服务来看：

![](http://i.imgur.com/77enI9p.jpg)![](http://i.imgur.com/kT5CzkO.jpg)![](http://i.imgur.com/MmXVsyt.jpg)

关于共享 DB 的几个说明 （主要来自 [这篇文章](http://www.joinfu.com/2015/01/understanding-reservations-concurrency-locking-in-nova/)）：

1. 根据该文章中的一个调查，被调查的 220 多个用户中，200 个在用 Mysql Galera，20 多个在用单 Mysql，只有一个用 PostgreSQL。
2. 以 Nova 为例，Mysql 使用 Write-intent locks 机制来保证多个连接同时访问数据库中的同一条记录时的互斥。以给新建虚机分配 IP 地址为例，该锁机制保证了一个 IP 不会分给两个用户。![](http://i.imgur.com/dkWvJw2.png)
3. 使用 Mysql Galera 时，所有节点都是 Master 节点，都可以接受服务，但是这里有个问题，Mysql Galera 不会复制 Write-intent locks。两个用户可以在不同节点上获取到同一条记录，但是只有一个能够修改成功，另一个会得到一个 Deadlock 错误。对于这种情况，Nova 使用 retry_on_deadlock 机制来重试，比如@oslo_db_api.wrap_db_retry(max_retries=5, retry_on_deadlock=True)。默认都是重试 5 次。但是，这种机制效率不高，文章作者提供了一种新的机制。

该 HA 方案具有以下优点：

- 多主，零切换，方便地实现负载均衡
- 将 API 服务和 DB, MQ 服务无缝整合在一起
- 由于这些优点，该方案被大量采用。具体配置请参考 [OpenStack High Availability Guide](https://docs.openstack.org/ha-guide/index.html)。

### 云控制节点的 `A/P HA` 方案

需要的话，可以使用 Pacemaker + Corosync 搭建两节点集群实现 A/P HA 方案。由主服务器实际提供服务，在其故障时由 Pacemaker 将服务切换到备服务器。OpenStack 给其组件提供了各种Pacemaker RA。对 Mysql 和 RabbitMQ 来说，可以使用 Pacemaker + Corosync + DRBD 实现 A/P HA。具体请参考 [理解 OpenStack 高可用（HA）（4）：RabbitMQ 和 Mysql HA](http://www.cnblogs.com/sammyliu/p/4730517.html)。具体配置请参考 [OpenStack High Availability Guide](https://docs.openstack.org/ha-guide/index.html)。

该 HA 方案的问题是：

- 主备切换需要较长的时间
- 只有主提供服务，在使用两个节点的情况下不能做负载均衡
- DRBD 脑裂会导致数据丢失的风险。A/P 模式的 Mysql 的可靠性没有 Mysql Galera 高。

因此，可以看到实际部署中，这种方案用得较少，只看到 Oracel 在使用这种方案。

## Neutron HA

Neutron 包括很多的组件，比如 L3 Agent，L2 Agent，LBaas，VPNaas，FWaas，Metadata Agent 等 Neutron 组件，其中部分组件提供了原生的HA 支持。这些组件之间的联系和区别：

![](http://images2015.cnblogs.com/blog/697113/201512/697113-20151204105128158-604514786.jpg)


