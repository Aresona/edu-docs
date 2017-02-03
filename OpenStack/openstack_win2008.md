### 关于制作openstack的windows2008镜像，目前先总结下面几点：

1. [参考文档](https://www.unixhot.com/article/70)
2. 上面文档里面的第4步不需要做
3. 进入系统后需要操作的步骤有：关闭防火墙、允许Administrator用户能够远程登录、Administrator用户设置密码永不过期、拷贝驱动程序到C:\Drivers目录下，以便以后用到;安装cloudbaseinitsetup程序。
4. 上面执行完后创建镜像文件

<pre>
qemu-img convert -f raw -O qcow2 windows-2008-x86_64.raw windows-2008-x86_64.qcow2
</pre>

5. 上传镜像

<pre>
glance image-create --name "win2008" --file windows-2008-x86_64.qcow2 --disk-format qcow2 --container-format bare --visibility public --progress
</pre>

6. 通过上传的镜像创建虚拟机
7. 创建完虚拟机后会发现网络是不可用的，这时需要重新加载网卡驱动，做完这一步后关闭虚拟机，然后把这个实例做成快照，以后所有的虚拟机都通过这个快照镜像来启动。

### 相关的文章

[windows image creation](https://maestropandy.wordpress.com/2014/12/05/create-a-windows-openstack-vm-with-virtualbox/)

[VirtIO ISO](https://launchpad.net/kvm-guest-drivers-windows/20120712/20120712/+download/virtio-win-drivers-20120712-1.iso)

[Cloud Base init](http://www.cloudbase.it/cloud-init-for-windows-instances/)
