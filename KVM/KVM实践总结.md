# KVM实践总结
## 安装相关包
<pre>
yum install qemu-kvm qemu-kvm-tools virt-manager libvirt virt-install -y
</pre>
## 创建虚拟机
**创建桥接网卡**
修改两个配置文件如下：
<pre>
[root@bogon network-scripts]# cat ifcfg-br0 
DEVICE=br0
ONBOOT=yes
TYPE=Bridge
BOOTPROTO=static
IPADDR=192.168.1.202
NETMASK=255.255.255.0
GATEWAY=192.168.1.1
DEFROUTE=yes
[root@bogon network-scripts]# cat ifcfg-em1
TYPE=Ethernet
BOOTPROTO=static
NAME=em1
DEVICE=em1
ONBOOT=yes
BRIDGE=br0

systemctl restart network
</pre>
**创建镜像**
<pre>
qemu-img create -f raw /opt/Centos-test.raw 10G
</pre>
**新建虚拟机**
<pre>
virt-install --name test --virt-type kvm --ram 1024 --cdrom=/home/CentOS-7-x86_64-DVD-1503.iso --disk path=/opt/Centos-test.raw --network bridge=br0	 --graphics vnc,listen=0.0.0.0,port=5911, --noautoconsole</pre>

**开启虚拟机**
<pre>virsh start test</pre>
> 通过tightvnc来连接并安装操作系统(192.168.1.202:5911),这里有一个小体验就是如果网络是不正确的话好像连不上VNC


**关闭虚拟机**
<pre>virsh shutdown test</pre>
## 转换镜像文件格式
**转换镜像格式raw为qcow2**
<pre>
yum install libguestfs-tools -y
virt-sparsify --compress --convert qcow2 /opt/Centos-test.raw /opt/CentOS-moban.qcow2
</pre>

**更改格式**
<pre>
virsh edit test
&lt;disk type='file' device='disk'>
  &lt;driver name='qemu' type='qcow2'/>
  &lt;source file='/opt/CentOS-moban.qcow2'/>
  &lt;target dev='vda' bus='virtio'/>
  &lt;address type='pci' domain='0x0000' bus='0x00' slot='0x06' function='0x0'/>
&lt;/disk>
</pre>

**重启**
<pre>virsh start test</pre>

## 虚拟机克隆
**复制镜像文件**
<pre>
cp /opt/Centos-moban.qcow2 /opt/Centos-moban1.qcow2
</pre>
**编辑新虚拟机的XML文件**
<pre>
virsh dumpxml test > /etc/libvirt/qemu/test1.xml
vim /etc/libvirt/qemu/test1.xml
  &lt;name>test1&lt;/name>
  &lt;uuid>/uuid>	# 改成空
  &lt;driver name='qemu' type='qcow2'/>
  &lt;source file='/opt/CentOS-moban1.qcow2'/>
删除      &lt;mac address='52:54:00:da:76:97'/>
</pre>
> 主要修改两部分内容，一是修改名字跟镜像文件位置 ，二是修改MAC地址和UUID，UUID改成空，MAC地址行直接删除掉，完成克隆重启后这两个地方会自动补充。还有一点需要注意的是要想让克隆后的虚拟机启动，第一份虚拟机必须是开启状态（也可能是通过 `dumpxml` 命令导出的配置文件的那台虚拟机，我这里就是前面创建的 `test.xml` 这个文件对应的虚拟机）。


**注册并开启新虚拟机**
<pre>
virsh define /etc/libvirt/qemu/test1.xml
virsh start test1
</pre>
> 接下来就是给虚拟机配置IP地址了


## libvirt XML文件格式
### 常规信息区域
<pre>
&lt;domain type='xen' id='3'>
    &lt;name>instance-name&lt;/name>
    &lt;uuid>d9ef885b-634a-4437-adb6-e7abe1f792a5&lt;/uuid>
    &lt;title>A short description - title - of the domain&lt;/title>
    &lt;description>Some human readable description&lt;/description>
    &lt;metadata>
        &lt;app1:foo xmlns:app1="http://app1.org/app1/">..&lt;/app1:foo>
        &lt;app2:bar xmlns:app2="http://app1.org/app2/">..&lt;/app2:bar>
    &lt;/metadata>
    ...
</pre>
其中，type是虚拟化类型，其值可以是kvm, xen, qemu, lxc, kqemu等。id是标识正在运行的虚拟机，可以省略。

* name

虚拟机的名字，可以由数字、字母、中横线和下划线组成。

* uuid

虚拟机的全局唯一标识，可以用uuidgen命令生成。如果在定义（define）或创建（create）虚拟机实例时省略，系统会自动分配一个随机值这个实例。

* title, description

这两个东西都可以省略，见名知义，如果有特殊需求可以加上。

* metadata

metadata可以被应用（applications）以xml格式来存放自定义的metadata，该项也可以省略。

### 操作系统启动区域

<pre>
    ...
    &lt;os>
        &lt;type arch='x86_64' machine='pc'>hvm&lt;/type>
        &lt;boot dev='hd'/>
        &lt;bootmenu enable='yes'/>
        &lt;kernel>/var/instances/instance-hostname/kernel&lt;/kernel>
        &lt;initrd>/var/instances/instance-hostname/ramdisk&lt;/initrd>
        &lt;cmdline>root=/dev/vda console=ttyS0&lt;/cmdline>
    &lt;/os>
    ...
</pre>

* type


虚拟机启动的操作系统类型，hvm表示操作系统是在裸设备上运行的，需要完全虚拟化。

* boot


boot属性的值可以是fd, hd, cdrom, network等，用来定义下一个启动方式（启动顺序）。该属性可以有多个。

* bootmenu


在虚拟机启动时是否弹出启动菜单，该属性缺省是弹出启动菜单。

* kernel


内核镜像文件的绝对路径。

* initrd


ramdisk镜像文件的绝对路径，该属性是可选的。

* cmdline


这个属性主要是在内核启动时传递一些参数给它。

### 内存和CPU区域

<pre>
  ...
    &lt;vcpu placement='static' cpuset="1-4,^3,6" current="1">2&lt;/vcpu>
    &lt;memory unit='KiB'>2097152&lt;/memory>
    &lt;currentMemory unit='KiB'>2000000&lt;/currentMemory>
  ...
</pre>

* vcpu


vcpu属性表示分配给虚拟机实例的最大CPU个数。其中cpuset表示该vcpu可以运行在哪个物理CPU上面，一般如果设置cpuset，那么placement就设置成static。current的意思是是否允许虚拟机使用较少的CPU个数（current can be used to specify whether fewer than the maximum number of virtual CPUs should be enabled）。vcpu下面的这几个属性貌似只在kvm与qemu中有。

* memory


memory表示分配给虚拟机实例的最大内存大小。unit是内存的计算单位，可以是KB, KiB, MB, MiB，默认为Kib。（1KB=10^3bytes，1KiB=2^10bytes）

* currentMemory


currentMemory表示实际分配给虚拟实例的内存，该值可以比memory的值小。

### 磁盘区域
<pre>
...
&lt;devices>
    &lt;emulator>/usr/bin/kvm&lt;/emulator>

    &lt;disk type='file' device='disk'>
        &lt;source file='/var/instances/instance-hostname/disk' />
        &lt;target dev='vda' bus='ide' />
    &lt;/disk>

    &lt;disk type='file' device='disk'>
        &lt;driver name='qemu' type='raw'/>
        &lt;source file='/var/instances/instance-hostname/disk.raw'/>
        &lt;target dev='vda' bus='virtio'/>
        &lt;alias name='virtio-disk0'/>
        &lt;address type='pci' domain='0x0000' bus='0x00' slot='0x04' function='0x0'/>
    &lt;/disk>

    &lt;disk type='block' device='disk'>
        &lt;driver name='qemu' type='raw'/>
        &lt;source dev='/dev/sdc'/>
        &lt;geometry cyls='16383' heads='16' secs='63' trans='lba'/>
        &lt;blockio logical_block_size='512' physical_block_size='4096'/>
        &lt;target dev='hda' bus='ide'/>
    &lt;/disk>
&lt;/devices>
...
</pre>

* emulator


模拟器的二进制文件全路径。

* disk


定义单块虚拟机实例上的磁盘。

type 可以是block, file, dir, network。分别表示什么意思就不多说了。

device 表示该磁盘以什么形式暴露给虚拟机实例，可以是disk, floppy, cdrom, lun，默认为disk。

* driver


可以定义对disk更为详细的使用结节。

* source


定义磁盘的源地址，由type来确定该值应该是文件、目录或设备地址。

* target


控制着磁盘的bus/device以什么方式暴露给虚拟机实例，可以是ide, scsi, virtio, sen, usb, sata等，如果未设置的系统会自动根据设备名字来确定。如： 设备名字为hda那么就是ide。

* mirror


这个mirror属性比较牛B，可以将虚拟机实例的某个盘做镜像，具体不细说了。

### 网络接口区域
<pre>
...
&lt;devices>
    &lt;interface type='bridge'>
        &lt;source bridge='br0'/>
        &lt;mac address='00:16:3e:5d:c7:9e'/>
        &lt;model type='virtio'/>
    &lt;/interface>
&lt;/devices>
...
</pre>
顾名思义
### 相关事件的配置
<pre>
    ...
    &lt;on_poweroff>destroy</on_poweroff>
    &lt;on_reboot>restart</on_reboot>
    &lt;on_crash>restart</on_crash>
    &lt;on_lockfailure>poweroff</on_lockfailure>
    ...
</pre>

* on_poweroff, on_reboot, on_crash

其属性值为遇到这三项时进行的操作，可以是以下操作：

destroy 虚拟机实例完全终止并且释放所占资源。
restart 虚拟机实例终止并以相同配置重新启动。
preserve 虚拟机实例终止，但其所占资源保留来做进一步的分析。
rename-restart 虚拟机实例终止并且以一个新名字来重新启动。

on_crash 还支持以下操作：

coredump-destroy crash的虚拟机实例会发生coredump，然后该实例完全终止并释放所占资源。
coredump-restart crash的虚拟机实例会发生coredump，然后该实例会重新启动。

* on_lockfailure（我对这个不了解）
当锁管理器（lock manager）失去对资源的控制时（lose resource locks）所采取的操作：

poweroff 虚拟机实例被强制停止。
restart 虚拟机实例被停止后再启动来重新获取它的锁（locks）。
pause 虚拟机实例会被暂停，并且当你解决了锁（lock）问题后可以将其手动恢复运行。
ignore 让虚拟机实例继续运行，仿佛一切都没发生过。

### 时间区域

<pre>
&lt;clock offset='localtime'/>
</pre>
offset支持utc, localtime, timezone, variable等四个值，表示虚拟机实例以什么方式与宿主机同步时间。（并不是所有虚拟化技术都支持这些模式）

### 图形管理接口
<pre>
...
&lt;devices>
    &lt;graphics type='vnc' port='5904'>
        &lt;listen type='address' address='1.2.3.4'/>
    &lt;/graphics>
    &lt;graphics type='vnc' port='-1' autoport='yes' keymap='en-us' listen='0.0.0.0'/>
&lt;/devices>
...
</pre>

type为管理类型，可以是VNC,rdp等。其中port可以自动分配（从5900开始分配）。

### 日志记录
<pre>
...
&lt;devices>
    &lt;console type='stdio'>
        &lt;target port='1'/>
    &lt;/console>
    &lt;serial type="file">
        &lt;source path='/var/instances/instance-hostname/console.log'/>
        &lt;target port="1"/>
    &lt;/serial>
&lt;/devices>
...
</pre>

以上意思是禁止字符设备的输入，并将其输出定向到虚拟机的日志文件中（domain log）。将设备的日志写到一个文件里（Device log），比如：开机时的屏幕输出。

如你所想，libvirt的XML配置文件不可能就这么项内容，还有很多很多配置及详细配置，我在此不写出了，想深入了解的话可以看参考资料部分。



**CPU热添加**


修改配置文件中最大CPU
<pre>
  &lt;vcpu placement='auto' current='1'>4&lt;/vcpu>
</pre>
> 修改后需要重启才能生效
热添加
<pre>
virsh setvcpus CentOS-7.1-x86_64 2 --live
</pre>

检验效果
<pre>
cat /sys/devices/system/cpu/cpu0/online
cat /sys/devices/system/cpu/cpu1/online
</pre>
**内存热添加**

首先修改配置文件中的最大内存数
<pre>
  &lt;memory unit='KiB'>4048576&lt;/memory>
</pre>

热添加内存(修改当前内存为3个G)

<pre>
virsh qemu-monitor-command test --hmp --cmd  balloon 3000
</pre>

> 热添加过后，如果想让下次开机后继续保持添加后的内存的话，还是需要加入到配置文件中;这条命令也支持缩小，所以在添加的时候一定要注意数字，万一写错后也要及时改过来，否则就悲剧了……

**开机自启动**

<pre>
virsh autostart test
</pre>
> 执行上面这条命令后实际上是在 `/etc/libvirt/qemu/autostart` 目录下面创建了一个软链接文件

**挂起服务器**




**实现virsh console功能**

<pre>
grubby --update-kernel=ALL --args="crashkernel=0 at 0 video=1024x768 console=ttyS0,115200n8 console=tty0 consoleblank=0"
</pre>

The serial port is called ttyS0 on Linux .
[虚拟化](https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/7/html/Virtualization_Deployment_and_Administration_Guide/sect-Troubleshooting-Troubleshooting_with_serial_consoles.html)

virsh reboot test 



查看物理设备上的口
<pre>setserial -g /dev/ttyS[0123]</pre>

[tty相关文档](http://www.tldp.org/HOWTO/Remote-Serial-Console-HOWTO/configure-kernel.html)



/home/nexus/sonatype-work/nexus/conf/nexus.xml