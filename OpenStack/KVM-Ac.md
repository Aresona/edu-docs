# KVM

## 传统数据中心面临的问题
**搭建服务有什么选择**

* IDC托管：买台机器－放到IDC－安装系统－部署应用－买个域名－绑定上去－对外访问

ICP备－ICP证备－文网文－接入备案（一般都找代理）

* IDC租用
* VPS
* 虚拟主机（最便宜），主要用来搭建服务

资源利用率低、资源分配不合理、自动化能力差（买机器、上架等）、初始成本高；机器三年后就过保了

## 云计算是什么
云计算是一个概念，指的是资源使用和交付的模式；它必须通过网络来使用，它要做到弹性计算、按需付费、快速扩展（云计算必须具备这三种功能），不用关心太多基础设施，都有云计算提供商提供。

## 云计算分类

1. 私有云（资源是固定的）
2. 公有云（最大问题是数据放在别人家）
3. 混合云（有临时需求的时候按需使用公有云）

## 云计算分层
* Iaas
* Paas
* Saas

# 虚拟化
虚拟化和云计算是两个概念。它们的关系就是云计算使用了虚拟化的技术；不用虚拟化也能使用云计算，比如lxd等技术。
## 内核级虚拟化技术（Kernel-based Virtual Machine,KVM）

## 虚拟化分类
* 硬件虚拟化（kvm）
* 软件虚拟化（qemu）


* 全虚拟化（KVM）
* 半虚拟化（xen）

半虚拟化比全虚拟化好，但是今天讲KVM全虚拟化，KVM是支持超配的，但是XEN不支持超配。

## 使用场景分类
* 服务器虚拟化
* 桌面虚拟化（图像显示层面有弊端，像呼叫中心、银行外包、教学场景、移动桌面）(基于openstack的桌面虚拟化）
* 应用虚拟化（很贵，把应用通过浏览器进行交付（思捷的xenapp，原理是装一个浏览器的插件ICA,通过这种通信，比较贵，按用户））

app.womai.com

# KVM
OpenStack默认的虚拟化技术就是KVM，它的目标就是创建出来一台虚拟机，所以要先学习KVM(内核级虚拟机技术)，最先是以色列一家公司开发的，后来被REDHAT收购。RHEV是红帽自己的企业级级虚拟化

这些技术没有成熟的时候老大是vmware的ESXI，它是基于vmware的vsphere套件开发的，

## QEMU
它是一种软件模拟器，它是一个虚拟化的软件，什么东西都能虚拟出来，KVM是内核级的虚拟机，但是它没有一些其他的设备，所以KVM就使用了QEMU的一部分稍加改造自己使用（用户态的），它是一个KVM-QEMU进程。
> qemu 全称Quick Emulator。是独立虚拟软件，能独立运行虚拟机（根本不需要kvm）。kqemu是该软件的加速软件。kvm并不需要qemu进行虚拟处理，只是需要它的上层管理界面进行虚拟机控制。虚拟机依旧是由kvm驱动。 所以，大家不要把概念弄错了，盲目的安装qemu和kqemu。qemu使用模拟器
环境准备
<pre>
grep -E '(vmx|svm)' /proc/cpuinfo
yum install qemu-kvm qemu-kvm-tools libvirt -y
</pre>
用途
<pre>
qemu-kvm-tools.x86_64 : KVM debugging and diagnostics tools
qemu-kvm.x86_64 : QEMU is a FAST! processor emulator
libvirt.x86_64 : Library providing a simple virtualization API
</pre>

启动
<pre>
systemctl enable libvirtd
systemctl start libvirtd
</pre>
<pre>
virbr0: flags=4099<UP,BROADCAST,MULTICAST>  mtu 1500
        inet 192.168.122.1  netmask 255.255.255.0  broadcast 192.168.122.255
        ether 52:54:00:8e:ef:af  txqueuelen 0  (Ethernet)
        RX packets 0  bytes 0 (0.0 B)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 0  bytes 0 (0.0 B)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
[root@linux-node1 ~]# ps -ef|grep dns
nobody    18815      1  0 23:14 ?        00:00:00 /sbin/dnsmasq --conf-file=/var/lib/libvirt/dnsmasq/default.conf --leasefile-ro --dhcp-script=/usr/libexec/libvirt_leaseshelper
root      18816  18815  0 23:14 ?        00:00:00 /sbin/dnsmasq --conf-file=/var/lib/libvirt/dnsmasq/default.conf --leasefile-ro --dhcp-script=/usr/libexec/libvirt_leaseshelper
</pre>
安装一个tightvnc客户端

创建虚拟机的硬盘
<pre>
qemu-img create -f raw /opt/CentOS-7-x86_64.raw 10G
</pre>
创建虚拟机
<pre>
yum install virt-install -y
virt-install --virt-type kvm --name CentOS-7-x86_64 --ram 2048 \
--cdrom=/opt/CentOS-7-x86_64-DVD-1511.iso --disk path=/opt/CentOS-7-x86_64.raw \
--network network=default --graphics vnc,listen=0.0.0.0 --noautoconsole
</pre>
tab net.ifnames=0 biosdevname=0  回车

标准分区   根分区 
根分区给20个G 系统盘

去掉UUID ，MAC地址，PEERDNS=no  ipv6去掉   /etc/resolv.conf
重启网卡   ip addr 
udev下规则去掉，常用软件装上
yum install net-tools -y
yum install vim screen mtr nc nmap tree lrzsz openssl-devel gcc glibc gcc-c++ make zip dos2unix sysstat mysql

装上后它是qemu用户启动的进程，它会再加一些常见的选项，可以使用进程管理工具来管理

# libvirt介绍
会启动一个后台进程，然后通过libvirtAPI来管理虚拟机

如果libvirtd服务停止了，虚拟机还能跑，说明libvirtd只是管理虚拟机，不跑虚拟机，这就是KVM的优势，只要机器不挂，就算其他的挂了也没关系

虚拟机是靠/etc/libvirtd/qemu/CentOS-7-x86_64来定义的，怎么使用libvirtAPI来管理虚拟机？

重要命令
<pre>
virsh dumpxml CentOS-7-x86_64 > backup.xml
virsh start 
virsh shutdown
virsh destroy
virsh undefine
virsh reboot
virsh snapshot-create
virsh snapshot-list
virsh define		恢复
virsh suspend
virsh resume
</pre>
> raw不支持快照；在qcow2里面镜像是一个基础的镜像，其他的操作会被单独记在一个文件里面。

## 对KVM虚拟机的调整
### CPU
修改CPU数量、模型
<pre>
[root@linux-node1 qemu]# virt-install --help|grep cpu
  --vcpus VCPUS         Number of vcpus to configure for your guest. Ex:
                        --vcpus 5
                        --vcpus 5,maxcpus=10,cpuset=1-4,6,8
                        --vcpus sockets=2,cores=4,threads=2,
  --cpu CPU             CPU model and features. Ex:
                        --cpu coreduo,+x2apic
                        --cpu host
</pre>
<pre>
virsh edit CentOS-7-x86_64
</pre>
<pre>
virsh setvcpus CentOS-7-x86_64 2 --live
<vcpu placement='auto' current=1
cat /sys/devices/system/cpu/cpu1/online
设置完后默认就是工作的，以前是不工作的，在windows上可能有一点问题
</pre>
### 内存
<pre>
virsh --help |grep monitor
virsh qemu-monitor-command CentOS-7-x86_64 --hmp --cmd ballon 512
virsh qemu-monitor-command CentOS-7-x86_64 --hmp --cmd info ballon 
</pre>

### 存储
系统镜像存储能不能扩，能，但是不要扩，加一个，
支持resize,但是resize数据有风险，生产不要干，因为它涉及到一些分区的东西 

## KVM磁盘
### 磁盘格式
存储方式不同分为raw（全镜像模式）/qcow2(稀疏模式）
<pre>
qemu-img info CentOS-7-x86_64
qemu-img convert -f raw -O qcow2 CentOS-7-x86_64.raw test.qcow2
qcow2有一个概念是cluster
</pre>

## KVM 网络
<pre>
brctl show
bridge name	bridge id		STP enabled	interfaces
virbr0		8000.5254008eefaf	yes		virbr0-nic
							vnet0
vnet0就是刚才启动虚拟机的IP地址，它其实是通过iptables来实现的，所以它会是一个瓶颈，桥接物理网卡是直接使用物理机的IP地址。
</pre>
创建一个桥接网卡，并把KVM改成桥接网卡

两种方式：

1. 写好一个脚本执行


<pre>
brctl addbr br0
brctl addif br0 eth0
brctl show
ip addr del dev eth0 192.168.56.11/24
ifconfig br0 192.168.56.11/24 up
ip ro li
route add default gw 192.168.56.2
ping baidu.com
</pre>
<pre>
virsh edit CentOS-7-x86_64
interface type='bridge'
source bridge='br0'
virsh shutdown CentOS-7-x86_64
virsh start CentOS-7-x86_64
</pre>


# 优化
三个方面 ： CPU、内存、IO
## CPU
KVM是一个进程，它会受到CPU的调度，可能会被调到任何一个CPU上，CPU有三级缓存，它就是把一些重要的数据放进去，而这个调度时就会造成cache miss,性能就会受到影响，所以我们可以把这个进程绑定到某一个CPU上，减少cache miss来提高它的性能。
<pre>
[root@linux-node1 ~]# taskset -cp 0 1368
pid 1368's current affinity list: 0-3
pid 1368's new affinity list: 0
这样就实现绑定了，性能提升不到10%，但已经不少了，因为一般多核之间的缓存是共享的，所以可能效果不怎么样；这样不灵活，使用率不平均。
</pre>
## 内存
能优化的也很少，但是需要开启内存的EPT技术，这也是在需要在bios里面开通的，KVM虚拟机是一个进程，虚拟内存、物理内存之间的映射会损耗性能，所以INTEL开发了一种技术就是EPT，只需要在bios里面打开就可以了。

还有一个是使用大页内存加快内存的寻址。默认一页是4096K，如果分给虚拟机的话就太小了，可以几M几M的分给它，现在操作系统也做了许多操作，大概可以提高10%以上的性能

cat /sys/kernel/mm/transparent_hugepage/enabled

这个是进行内存的合并，会把连续的内存合并成一个2M的大小，减少内存碎片，默认也是开启的，

##　IO

默认情况下使用的是virtio，它是一种半虚拟化的技术，默认就是最好的。

### IO的调度算法
机械硬盘顺序读写比随机读写快，操作系统有一个IO调度器，希望碰头往一个方向运行
cat /sys/block/sda/queue/scheduler

centos7默认有三种，7里面是deadline,

noop就是啥也不干，用了一个简单的FIFO的队列，如果磁盘是SSD的话，一定要设置成NOOP，这样才会更快。它是针对磁盘的

CFQ是完全公平的IO调度，6里面它是默认的调度算法，对于通用的服务来说，CFQ是最好的。

DEADLINE，它是一个截止时间调度程序，使用了四个队列，分别包含读请求和写请求，目标是避免请求被饿死，防止写操作不能被读取而被饿死。一般会给数据库设置成这个算法会比较优一些

AS在centos7里面是没有的
<pre>
echo noop > /sys/block/sda/queue/scheduler
vim /boot/grub/menu.lst,加到kernel里面
</pre>

### KVMIO
有了虚拟机之后会有一个cache层，I/O cache；
应用程序在写磁盘的时候会写page cache,然后再有一个进程把脏数据写到硬盘里面，使用虚拟机后就会有两层page cache，这里又有几种算法：writeback(同时使用虚拟机物理机两层cache，不解决一致性问题)、None、WriteThrough（剩下这两层都会绕过物理机的cache写入磁盘），KVM默认使用的是WriteThrough,经过两层性能会更好，断电数据可能会丢失，writethrough性能会差，直接绕过两层cache,KVM选择保证数据一致 性。
<pre>

yum install docker -y
systemctl start docker
docker pull centos
docker pull nginx

</pre>