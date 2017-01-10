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

不仅一个文件可以分配给客户机作为虚拟磁盘，宿主机上VG中的LV也可以作为虚拟磁盘分配给虚拟机使用。不过LV由于没有磁盘MBR引导记录，不能作为虚拟机的启动盘，只能作为数据盘使用

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



