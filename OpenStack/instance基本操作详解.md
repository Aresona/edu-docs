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