# KVM实践总结
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
IPADDR=192.168.1.202
NETMASK=255.255.255.0
GATEWAY=192.168.1.1
DNS1=202.106.0.20
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
> 主要修改两部分内容，一是修改名字跟镜像文件位置 ，二是修改MAC地址和UUID，UUID改成空，MAC地址行直接删除掉，完成克隆重启后这两个地方会自动补充。


**注册并开启新虚拟机**
<pre>
virsh define /etc/libvirt/qemu/test1.xml
virsh start test1
</pre>
> 接下来就是给虚拟机配置IP地址了

