# [Cinder](http://www.cnblogs.com/CloudMan6/p/5573159.html)
## 理解 `Block Storage`
操作系统获得存储空间的方式一般有两种：

1. 通过某种协议(SAS,SCSI,SAN,ISCSI等)挂接裸硬盘，然后分区、格式化、创建文件系统；或者直接使用裸硬盘存储数据(数据库)
2. 通过NFS、CIFS等协议，mount远程的文件系统

第一种裸硬盘的方式叫做 `Block Storage` (块存储)，每个裸硬盘通常也称作Volume(卷)，第二种叫做文件系统存储。NAS和NFS服务器，以及各种分布式文件系统提供的都是这种存储。

## 理解 `Block Storage Service`

`Block Storage Service` 提供对 `volume` 从创建到删除整个生命周期的管理。

从instance的角度看，挂载的每一个 `volume` 都是一块硬盘。

OpenStack提供 `Block Storage Service` 的是 `cinder`，其具体功能是：

1. 提供`REST API`使用户能够查询和管理 `volume`、`volume snapshot`以及 `volume type`
2. 提供scheduler调度volume创建请求，合理优化存储资源的分配。
3. 通过driver架构支持多种back-end(后端)存储方式，包括LVM,NFS,Ceph和其他诸如EMC、IBM等商业存储产品和方案

## Cinder架构

下面是cinder服务的逻辑架构图

![](http://7xo6kd.com1.z0.glb.clouddn.com/upload-ueditor-image-20160610-1465514629979036483.jpg?_=5573159)

cinder包含如下几个组件：

* cinder-api
* cinder-volume
* cinder-scheduler
* vomlume provider
* Message Queue
* Database

## 物理部署方案

Cinder 的服务会部署在两类节点上，控制节点和存储节点。

为什么cinder-volume可以部署在控制节点上？

1. OpenStack 是分布式系统，其每个子服务都可以部署在任何地方，只要网络能够连通
2. 无论是哪个节点，只要上面运行了cinder-volume,它就是一个存储节点，当然，该节点上也可以运行其他OpenStack服务。
3. `cinder-volume` 是一顶存储节点帽子, `cinder-api` 是一顶控制节点帽子。在我们的环境中，控制节点同时戴上了这两顶帽子，我们也可以使用一个专门的节点来运行 `cinder-volume`

<pre>
cinder service-list
</pre>

可以通过这条命令查看cinder-*子服务都分布在哪些节点上。

`volume provider`放在哪里？

一般来讲，`voume provider`是独立的。`cinder-volume` 使用 `driver`与`volume provider`通信并协调工作。所以只需要将 `driver` 与 `cinder-volume`放在一起就可以了。在`cinder-volume`的源代码目录下有很多 `driver`,支持不同的`volume provider`。另外，`NFS`和`LVM`都属于 `volume provider`。
