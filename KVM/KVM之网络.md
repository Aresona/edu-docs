# 网络虚拟化技术与应用场景
一个完整的数据包从虚拟机到物理机的路径是：虚拟机 --> QEMU虚拟网卡 --> 虚拟化层 --> 内核网桥 --> 物理网卡

KVM的网络优化方案：总的思路就是主汉人机访问物理网卡的层数更少，直至对物理网卡单独占领，和物理机一样使用物理网卡，以达到和物理机一样的网络性能。

Open vSwitch主要解决虚拟化网络的管理问题。Open vSwitch一方面将宿主机内部的网络和物理网络打通，方便网络管理员的管理；另一方面整合了虚拟网络管理方面的需求，实现了通过一个统一的工具虚拟化网络。

## 半虚拟化网卡技术详解 
KVM中，默认情况下网络设备是由QEMU在Linux的用户空间模拟出来并提供给虚拟机的。这样做的好处是通过模拟可以提供给虚拟机多种类型的网卡，提供最大的灵活性。但是由于网络I/O的过程需要虚拟化引擎参与，由此产生了大量的vm exit、vm entry,效率低下。 所以产生了全虚拟化网卡和半虚拟化技术。

半虚拟化网卡与全虚拟化网卡的区别是全虚拟化网卡是虚拟化层完全模拟出来的网卡，半虚拟化网卡通过驱动对操作系统做了改造。在实际应用中，使用较多的是半虚拟化网卡技术，即Virtio技术。Virtio驱动因为改造了虚拟机操作系统，让虚拟机可以直接和虚拟化层通信，从而大大提高了虚拟机的性能。

### 配置半虚拟化网卡
要使用Virtio必须要在宿主机和客户机中分别安装Virtio驱动，这样客户机的I/O就可以以Virtio的标准接口来进行，而虚拟化引擎不需要捕捉这些I/O请求，这样就提高了性能。
#### 系统对Virtio支持
Linux内核从2.6.24开始支持Virtio，因此宿主机只需要较新的Linux内核即可。对于虚拟机来说可以查看配置文件看看是否支持
<pre>[root@localhost ~]# grep -i Virtio /boot/config-3.10.0-327.el7.x86_64 
CONFIG_VIRTIO_BLK=m
CONFIG_SCSI_VIRTIO=m
CONFIG_VIRTIO_NET=m
CONFIG_VIRTIO_CONSOLE=m
CONFIG_HW_RANDOM_VIRTIO=m
CONFIG_VIRTIO=m
# Virtio drivers
CONFIG_VIRTIO_PCI=m
CONFIG_VIRTIO_PCI_LEGACY=y
CONFIG_VIRTIO_BALLOON=m
CONFIG_VIRTIO_INPUT=m
# CONFIG_VIRTIO_MMIO is not set
</pre>
windows虚拟机则需要额外安装Virtio的Windows版驱动。
#### 配置
配置半虚拟化网卡的方法有两种

* 在虚拟机启动命令中加入virtio-net-pci参数
<pre>
QEMU-system-x86_64 -boot c -drive \
file=/images/xpbase.qcow2,if=virtio -m 384 -netdev \
type=tap,script=/etc/KVM/QEMU-ifup,id=net0 -device \
virtio-net-pci,netdev=net0
</pre>
* 使用Libvirt管理KVM虚拟机，可以修改xml配置文件，配置文件如下：
<pre>
&lt;interface type='bridge'/>
&lt;mac address='fa:16:3e:fc:e0:c0'/>
&lt;source bridge='br0'/>
&lt;model type='Virtio'/>
&lt;address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x0'/>
&lt;/interface>

` &lt;model type='Virtio'/>` 指定了使用Virtio网卡。如果要使用全虚拟化网卡，使用 `&lt;model type='e1000'/>` 。如果没有指定model type关键字，默认是8139的全虚拟化网卡。e1000模拟的是Intel公司的千兆网卡，8139模拟是早期的Realtek公司的百兆网卡。
由于实际中多数使用Libvirt管理虚拟机，因此第二种方法用得更多。


### 全虚拟化网卡、半虚拟化网卡性能比较
全虚拟化网卡的性能与Virtio半虚拟化网卡的性能非常明显。通常用两个方面的数据来衡量网卡性能：

* 吞吐率（即带宽）bit/s
* 每秒发包数pps

通常情况下，更多地使用前者来衡量网卡性能，但是实际使用中经常发现，如果服务器承载的是游戏或者web服务等需要大量收发小包的业务，即使没有被撑满也会出现性能瓶颈，这时就是受到了“每秒发包数”这个指标的了如指掌。

## MacVTap和vhost-net技术原理与应用
vhost_net技术使虚拟机的网络通信绕过用户空间的虚拟化层，可以直接和内核通信，从而提供虚拟机的网络性能，MacVTap则是跳过内核的网桥。使用vhost_net，必须使用Virtio半虚拟化网卡。

MacVlan的功能是给同一个物理网卡配置多个MAC地址，这样就可以在软件上配置多个以太网口，属于物理层的功能。MacVTap是用来替代TUN/TAP和Bridge内核模块的。MacVTap是基于MacVlan这个模块，提供TUN/TAP中TAP设备使用的接口，使用MacVTap以太网口的虚拟机能够通过TAP设备接口，直接将数据传递到内核中对应的MacVTap以太网口。

vhost_net是对于Virtio的优化。Virtio本来是设计用于进行客户系统的前端与VMM的后端通信，减少硬件虚拟化方式下根模式和非根模式的切换。vhost-net是对于Virtio的优化，Virtio是虚拟化层的前端优化方案，减少硬件虚拟化方式下根模式与非根模式的切换，而vhost-net是虚拟化层后端优化方案。不使用vhost-net,进入CPU的根模式后，需要进入用户态将数据发送到tap设备后，再次切入内核态，使用vhost-net方式后，进入内核态后不需要再进行内核态用户态的切换，进一步减少特权级切换的开销。

> Tun/Tap都是虚拟网卡，没有直接映射到物理网卡，是一种纯软件的实现。Tun是三层虚拟设备，能够处理三层即IP包，Tap是二层设备，能处理链路层网络包如以太网包。

### MacVTap技术与应用 
MacVTap同传统的桥接方案相比，其优点主要是支持新的虚拟化网络技术，可以将宿主机CPU的一些工作交给网络设备。
#### 传统桥接方案
传统的Linux网络虚拟化技术采用的是TAP+Bridge方式，将虚拟机连接到虚拟的TAP网卡，然后将TAP网卡加入到Bridge。Bridge相当于用软件实现的交换机。这种解决方案实际上就是用服务器的CPU通过软件模拟网络。
下面是前面出现过的虚拟机网卡配置文件
<pre>
&lt;interface type='bridge'/>
&lt;mac address='fa:16:3e:fc:e0:c0'/>
&lt;source bridge='br0'/>
&lt;model type='Virtio'/>
&lt;address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x0'/>
&lt;/interface></pre>
其中<target dev='tap0'/>的tap0就是一个TAP设备，只不过其中的一些参数已经换成了具体的配置。可以通过ifconfig查看tap0的情况。

tap0被加入到了br0中，可以理解为tap0是交换机br0上的一个端口，虚拟机的网卡则连接到了这个端口。
<pre>
[root@localhost ~]# brctl show br0
bridge name	bridge id		STP enabled	interfaces
br0		8000.44a8423108fd	no		em1（tap0）
</pre>
> 这里的em1就是上面说到的tap0

以上就是传统的TAP+Brideg虚拟化网络技术，这种技术有3个缺点：

* 每台宿主机内都存在Bridge，会使网络拓扑变复杂，相当于增加了交换机的级联层数
* 同一宿主机上的虚拟机之间的流量直接在Bridge完成交换，使流量监控、监管困难。
* Bridge是软件实现的二层交换技术，会加大服务器的负担。

### 网卡PCI Passthrough的应用场景
PCI Passthrough技术是虚拟化网卡的终极解决方案，能够让虚拟机独占物理网卡，达到最优性能，可以在网卡性能要求非常高的场景使用。但是因为PCI Passthrough是独占网卡，所以对宿主机的网卡数据有要求。目前主流的服务器都有4块以上的网卡，实际使用的时候，可以将1~2志块网卡通过PCI Passthrough技术分给网络压力非常大的虚拟机，然后其他虚拟机共享剩余的网卡。


# 磁盘
## 磁盘镜像格式
KVM虚拟机的磁盘镜像从存储方式上看，可以分为两种方式，第一种方式为存储于文件系统上，第二种方式为直接使用裸设备。裸设备的使用方式可以是直接使用裸盘，也可以是使用LVM的方式。存于文件系统上的镜像有多种格式，经常使用的是raw和qcow2。

## QUMU支持的磁盘镜像格式
* RAW 

RAW格式是简单的二进制镜像文件，一次性会把分配的磁盘空间占用。raw支持稀疏文件特性，稀疏文件特性就是文件系统会把分配的空字节文件记录在元数据中，而不会实际占用磁盘空间。Linux常用的ext4、xfs文件系统都支持稀疏特性，Windows系统的ntfs也支持稀疏特性。所以在ext4文件系统上，用ls命令和du命令看到的大小是不一样的。使用ls命令看到的是分配的大小，使用du命令看到的是实际使用的大小。如果希望实际分配和占用的大小一致 ，我们可以使用dd命令创建raw的虚拟机镜像文件。

* qcow2 

第二代的QEMU写时复制格式，支持很多特性，如快照、在不支持稀疏特性的文件系统上也支持精简方式、AES加密、ZLIB压缩、后备方式。


### 镜像创建及查看
#### 创建
镜像的创建使用qemu-img create命令，可以使用-f参数指定镜像格式，不指定时默认为raw格式。比如创建一个50G、名字为test的raw格式的镜像，命令为：

<pre>qemu-img create test 50G</pre>

创建一个50G的镜像，格式为qcow2，名字为test.qcow2,命令为
<pre>qemu-img create test.qcow2 -f qcow2 50G</pre>
### 镜像信息查看
<pre>
qemu-img info test
</pre>
### QEMU镜像格式转换
* 镜像格式转换

使用qemu-img convert命令可以转换镜像格式。比如将刚才创建的test镜像转换为名为test1.qcow2的qcow2镜像格式，命令如下：
<pre>
qemu-img convert -p -f raw -O qcow2 test test1.qcow2
</pre>
-p是显示转换进度，-f是指原有的镜像格式，－O是输出的镜像格式，然后是输入文件和输出文件
* 压缩镜像的转换

如果要做镜像压缩和加密，只能使用convert方式。将test`.qcow2压缩的命令为：
<pre>
qemu-img convert -c -f qcow2 -O qcow2 test2.qcow2 test3.qcow2
</pre>
只有qcow2支持压缩特性，压缩使用zlib算法，压缩是块级别的压缩，并且是只读的，就是当压缩的块被 重写的时候，是不压缩的。qcow2镜像的压缩在镜像被传输的时候特别有意义，因为是块级的压缩，要比用tar压缩效率高很多。

磁盘转换主要用于不同虚拟化产品的虚拟机镜像转换，比如将VMware的vmdx转换成KVM专用的qcow2格式。

### QEMU镜像快照

raw格式不支持快照，只有qcow2格式才支持快照，快照使用qemu-img的参数snapshot管理。

* 快照创建使用-c参数和快照的名字。例如创建名为sl的快照，使用如下命令。

<pre>
qemu-img snapshot test.qcow2 -c s1
</pre>
* 快照查看，使用-l参数

<pre>
qemu-img snapshot test.qcow2 -l
</pre>

* 删除快照，使用-d参数 

<pre>
qemu-img snapshot test.qcow2 -d s2
</pre>

* 还原快照，使用-a参数

<pre>
qemu-img snapshot test.qcow2 -a s1
</pre>

* 快照单独提取镜像，可以使用convert参数进行转换

<pre>
qemu-img convert -f qcow2 -O qcow2 -s s1 test.qcow2 test-s1.qcow2
</pre>

快照的原理是利用写时复制的机制，所以快照对性能有影响，生产环境建议最多创建一次快照。

* 增加镜像大小

<pre>
qemu-img resize test2.qcow2 +5G
qemu-img resize test2.qcow2 70G
</pre>

> qcow2镜像不支持镜像缩小，如果缩小会报错；raw镜像可以缩小

<pre>
qemu-img resize test 20G
</pre>

> 镜像缩小的时候，要先将分区和文件系统缩小，否则会造成数据丢失。



