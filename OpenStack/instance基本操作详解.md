# OpenStack操作过程分析

-----------------------------------

## Lauch Instance

![](http://7xo6kd.com1.z0.glb.clouddn.com/upload-ueditor-image-20160505-1462406161564029503.png?_=5460464)

1. 客户（可以是 OpenStack 最终用户，也可以是其他程序）向 API（nova-api）发送请求：“帮我创建一个 Instance”
2. API对请求做一些必要处理后，向 Messaging（RabbitMQ）发送了一条消息：“让 Scheduler 创建一个 Instance”
3. Scheduler（nova-scheduler）从 Messaging 获取到 API 发给它的消息，然后执行调度算法，从若干计算节点中选出节点 A
4. Scheduler 向 Messaging 发送了一条消息：“在计算节点 A 上创建这个 Instance”
5. 计算节点 A 的 Compute（nova-compute）从 Messaging 中获取到 Scheduler 发给它的消息，然后通过本节点的 Hypervisor Driver 创建 Instance。
6. 在 Instance 创建的过程中，Compute 如果需要查询或更新数据库信息，会通过 Messaging 向 Conductor（nova-conductor）发送消息，Conductor 负责数据库访问。

## Start Instance

![](http://7xo6kd.com1.z0.glb.clouddn.com/upload-ueditor-image-20160508-1462691432646002227.jpg?_=5470723)

1. 向nova-api发送请求
2. nova-api发送消息
3. nova-compute执行操作


## Shutoff

![](http://7xo6kd.com1.z0.glb.clouddn.com/upload-ueditor-image-20160505-1462406117362002622.jpg?_=5460464)

1. 向nova-api发送请求
2. nova-api发送消息
3. nova-compute执行操作

## Terminate

![](http://7xo6kd.com1.z0.glb.clouddn.com/upload-ueditor-image-20160512-1463039865145016017.jpg?_=5486066)

1. 向nova-api发送请求
2. nova-api发送消息
3. nova-compute执行操作

> 执行teminate的时候会关闭instance、删除instance的镜像文件、释放虚拟网络等其他资源。

## Pause/Resume

### Pause

![](http://7xo6kd.com1.z0.glb.clouddn.com/upload-ueditor-image-20160516-1463348249257038197.jpg?_=5496825)

1. 向nova-api发送请求
2. nova-api发送消息
3. nova-compute执行请求


## Rescue/Unrescue

![](http://7xo6kd.com1.z0.glb.clouddn.com/upload-ueditor-image-20160517-1463495354677099617.jpg?_=5503501)

Rescue 用指定的 image 作为启动盘引导 instance，将 instance 本身的系统盘作为第二个磁盘挂载到操作系统上。

* 向nova-api发送请求（只能通过CLI执行，另外，没有指定用哪个image做引导盘，默认将使用部署时使用的）
* nova-api发送消息
* nova-compute执行操作，如下：

<pre>
1. 关闭instance
2. 通过image创建新的引导盘
3. 启动instance
</pre>

> rescue执行成功后，instance的状态就是rescued,还可以通过XML文件看到引导盘为vda,而真正的引导盘为vdb;最后修复完后会可以通过unrescue来从原启动盘重新引导instance。

## Snapshot

Nova的备份操作叫snapshot,其工作原理是对instance的镜像文件（系统盘）进行全量备份，生成一个类型为snapshot的image,然后将其保存在Glance上。

![](http://7xo6kd.com1.z0.glb.clouddn.com/upload-ueditor-image-20160519-1463665376908062417.jpg?_=5510296)

1. 向 nova-api 发送请求
2. nova-api 发送消息
3. nova-compute 执行操作

通过日志可以看到nova-compute执行的步骤如下：

1. VM Paused
2. qemu-img convert -f qcow2 -O qcow2
3. VM Started
4. VM Resumed
5. Snapshot image upload

## Rebuild

如果instance损坏了，可以通过snapshot恢复，这个恢复的操作就是rebuild,rebuild会用snapshot替换instance当前的镜像文件，同时保持instance的其他诸如网络，资源分配属性不变

![](http://7xo6kd.com1.z0.glb.clouddn.com/upload-ueditor-image-20160522-1463901712150009866.jpg?_=5516852)

1. 向nova-api发送请求
2. nova-api发送消息
3. nova-compute执行操作

详细操作如下：

1. 关闭虚拟机(shutdown instance)
2. 下载新的image,并准备instance的镜像文件(qemu-img create -f qcow2 -o backing_file)
3. 启动instance(start instance)
4. instance spawned


## Shelve

instance被suspend后虽然处于shutdown状态，但Hypervisor依然在宿主机上为其预留了资源，以便在以后能够成功Resume.如果想释放这些预留资源，可以使用shelve操作。Shelve会将instance作为image保存到glance中，然后在宿主机上删除该instance.

![](http://7xo6kd.com1.z0.glb.clouddn.com/upload-ueditor-image-20160524-1464048229786035236.jpg?_=5524751)

1. 向nova-api发送请求
2. nova-api发送消息
3. nova-compute执行操作

nova-compute详细操作如下 ：

1. 关闭instance(shutdown instance)
2. 对instance执行snapshot操作(begining cold snapshot process)
3. convert -f qcow2 -O qcow2
4. snapshot extracted
5. 生成image,并上传到glance(snapshot image upload)
6. 删除instance在宿主机上的资源

## Unshelve

因为 Glance 中保存了 instance 的 image，unshelve 的过程其实就是通过该 image launch 一个新的 instance，nova-scheduler 也会调度合适的计算节点来创建该 instance。 instance unshelve 后可能运行在与 shelve 之前不同的计算节点上，但 instance 的其他属性（比如 flavor，IP 等）不会改变。

![](http://7xo6kd.com1.z0.glb.clouddn.com/upload-ueditor-image-20160526-1464217272156085924.png?_=5529915)

1. 向 nova-api 发送请求
2. nova-api 发送消息
3. nova-scheduler 执行调度
4. nova-scheduler 发送消息
5. nova-compute 执行操作

nova-compute 执行 unshelve 的过程与 launch instance 非常类似。
一样会经过如下几个步骤：
1.	为 instance 准备 CPU、内存和磁盘资源
2.	创建 instance 镜像文件
3.	创建 instance 的 XML 定义文件
4.	创建虚拟网络并启动 instance

## Migrate

Migrate操作的作用是将instance从当前的计算节点迁移到其他节点上。

Migrate不要求源和目标节点必须共享存储，当然共享存储也是可以的。Migrate前必须满足一个条件：计算节点间需要配置nova用户无密码访问

![](http://7xo6kd.com1.z0.glb.clouddn.com/upload-ueditor-image-20160528-1464447095630076998.jpg?_=5538599)

### 如果源节点和目标节点是同一个，Migrate操作会怎样进行呢？

实验得知，nova-compute在做migrate的时候会检查目标节点，如果发现目标节点与源节点相同，会抛出UnableToMigrateToSelf异常。nova-compute失败之后，scheduler会重新调度，由于有RetryFilter，会将之前选择的源节点过滤掉，这样就能选到不同的计算节点了。

### nova-compute详细操作

1. 开始Migrate(Starting migrate disk and power off migrate_disk_and_power_off)
2. 在目标节点instance目录里面创建(nova用户)临时文件，如果touch不了，说明不是共享存储，这时就先创建目录，再创建文件
3. 关闭instance
4. 重命名磁盘文件父目录，然后scp到目标节点相应目录
5. 在目标节点上启动instance
6. 当启动后在dashboard上的状态会显示 `comfirm Resize/Migrate`，其实是给了用户一个反悔的机会，如果确定后就会在源节点删除磁盘文件并删除虚拟机，目标节点不需要做任何事。
7. 而当执行 `revert Resize/Migrate`的时候会在目标节点上关闭instance,删除instance目录，并在hypervisor上删除instance.然后在源节点上重新启动。

## Resize

Resize的作用是调整instance的vCPU、内存和磁盘资源，Resize操作是通过为instance选择新的flavor来调整资源的分配。另外，因为需要分配的资源发生了变化，在resize之前需要借助nova-scheduler重新为instance选择一个合适的计算节点，如果选择的节点与当前节点不是同一个，那么就需要做Migrate.

所以本质上讲：Resize是在Migrate的同时应用新的flavor,Migrate可以看做是resize的一个特例：flavor没发生变化的resize,这也是为什么在日志中看到migrate实际上是在执行resize操作。

![](http://7xo6kd.com1.z0.glb.clouddn.com/upload-ueditor-image-20160601-1464731997551085708.jpg?_=5548294)

1. 向nova-api发送请求
2. nova-api发送信息
3. nova-scheduler执行调度
4. nova-scheduler发送消息
5. nova-compute 执行操作

Resize分两种情况：

1. nova-scheduler选择的目标节点与源节点是不同节点。这时跟Migrate是一样的，只是在目标节点启动instance的时候按新的flavor分配资源。
2. 目标节点与源节点是同一节点，则不需要Migrate,

### 实际日志显示

1. 执行新实例flavor
2. nova-scheduler执行调度
3. nova-scheduler发送消息
4. nova-compute执行操作(为新instance准备资源/关闭instance/准备镜像文件(备份并复制回来一份)/创建instance的XML文件/准备虚拟网络/启动instance)

### comfirm

执行confirm后删除备份目录instance_id_resize；而如果执行revert后，会在目标节点上先删除instance,并在源节点上恢复节点启动。

## Live Migrate

Migrate操作会先将instance停掉，也就是所谓的“冷迁移”。而Live Migrate是在线迁移，instance不会停机

Live Migrate分两种：

1. 源和目标节点没有共享存储，instance在迁移的时候需要将其镜像文件从源节点传到目标节点，这叫做Block Migration(块迁移)
2. 源和目标节点共享存储，instance的镜像文件不需要迁移，只需要将instance的状态迁移到目标节点


源和目标节点需要满足一些条件才能支持Live Migration:

1. 源和目标节点的CPU类型一致
2. 源和目标节点的Libvirt版本要一致
3. 源和目标节点能相互识别对方的主机名称，比如可以在 `/etc/hosts`　中加入对方的条目。
4. 源和目标节点的 `/etc/nova/nova.conf`　中指明在线迁移时使用TCP协议
5. instance使用config driver保存其metadata.在Block Migration过程中，该config driver也需要迁移到目标节点，由于目前libvirtd只支持迁移vfat类型的config driver，所以必须在 `/etc/nova/nova.conf`　中明确指明launch instance时创建vfat类型的config driver
6. 源和目标节点的Libvirt TCP远程监听服务得打开，需要在下面两个配置文件中做一点配置

<pre>
[libvirt]
live_migration_uri = qemu+TCP://stack@%s/system
[DEFAULT]
config_drive_format = vfat
</pre>
`/etc/libvirt/libvirtd.conf`
<pre>
listen_tls = 1
listen_tcp = 1
listen_addr = "0.0.0.0"
unix_sock_group = "libvirtd"
unix_sock_ro_perms = "0777"
unix_sock_rw_perms = "0770"
auth_unix_ro = "none"
auth_unix_rw = "none"
auth_tcp = "none"
</pre>
`/etc/sysconfig/libvirtd`
<pre>
LIBVIRTD_ARGS="--listen"
</pre>

### 非共享存储Block Migration

![](http://7xo6kd.com1.z0.glb.clouddn.com/upload-ueditor-image-20160602-1464875387118021710.jpg?_=5554549)

1. 向nova-api发送消息（指定目标节点），因为是非共享存储，所以要勾上 `Block Migration`；另外还有一个`Disk Over Commit`如果勾上的话表示在检查目标节点磁盘的时候是以XML文件里面最大磁盘容量来判断，如果不勾的话就是以实际大小来判断。
2. 将instance的数据（镜像文件、虚拟网络资源）等迁移到目标节点
3. 



需要练习的日志：

1. Lock/Unlock
2. Soft/Hard Reboot
3. Shutoff
4. Suspend/Resume
5. Unrescue
6. 



## Pause和Suspend的区别：

**相同点**

两者都是暂停 instance 的运行，并保存当前状态，之后可以通过 Resume 操作恢复

**不同点**

1.	Suspend 将 instance 的状态保存在磁盘上；Pause 是保存在内存中，所以 Resume 被 Pause 的 instance 要比 Suspend 快。
2.	Suspend 之后的 instance，其状态是 Shut Down；而被 Pause 的 instance 状态是Paused。
3.	虽然都是通过 Resume 操作恢复，Pause 对应的 Resume 在 OpenStack 内部被叫作 “Unpause”；Suspend 对应的 Resume 才是真正的 “Resume”。这个在日志中能体现出来。