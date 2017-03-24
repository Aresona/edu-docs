# OpenStack常用命令行操作

### Resume用指定的image作为启动盘引导 `instance`,将 `instance` 本身的系统盘作为第二个磁盘挂载到操作系统上。
<pre>
nova rescue server
nova rescue --image xxx.img server
</pre>
如果不指定 `image` 的话，nova将使用 `instance` 部署时使用的 `IMAGE`；首先通过qemu-create一块盘，然后通过这块盘来启动，把真正的启动盘作为第二块盘。可以通过 `virsh edit` 命令看到。

### Rescue完成后可以通过 `unrescue` 命令生产引导

<pre>
nova unrescue <server>
</pre>

### 撤离虚拟机

Evacuate 可在 nova-compute 无法工作的情况下将节点上的 instance 迁移到其他计算节点上。但有个前提： Instance 的镜像文件必须放在共享存储上。 

<pre>
nova evacuate c2 --on-shared-storage
</pre>
`evacuate` 实际上是通过 `rebuild` 操作实现的。因为 `evacuate` 是用共享存储上的 `instance` 的镜像文件重新创建虚拟机。

<pre>
cinder service-list
nova service-list
neutron agent-list
openstack endpoint show cinder
neutron router-list
</pre>



## Tips

1. 执行snapshot的时候会先 `paused instance` ,然后 `qemu-convert` 磁盘文件，然后恢复 `instance`，最后上传snapshot。
2. 通过 `snapshot` 恢复的操作就是 `rebuild` ， `Rebuild` 会用 `snapshot` 替换 `instance` 当前的镜像文件，同时保持 `instance` 的其他诸如网络，资源分配属性不变。
3. 废弃实例会将 `instance` 作为 `image` 保存到 `Glance` 中，然后在宿主机上删除该 `instance` 。这样才会释放 snapshot的资源。
4. 





