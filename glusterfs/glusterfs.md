# 使用glusterfs构建中小企业内部分布式存储

## 安装向导

### 必要条件

1. Fedora22以上最少两台机器
2. 网络连接
3. 最少两块硬盘,一块装系统,另一块用做SDB,分离操作系统和文件系统
> glusterfs会自动在 `/var/lib/glusterd` 下生成配置文件;可以把/var/log目录单独放在一个分区上,避免损失

### 格式化并挂载

所有节点执行
<pre>
mkfs.xfs -i size=512 /dev/sdb1
mkdir -p /data/brick1
echo '/dev/sdb1 /data/brick1 xfs defaults 1 2' >> /etc/fstab
mount -a && mount
</pre>



#磁盘格式化基础知识
<pre>
yum install -y xfsprogs
mkfs
</pre>
> CetnOS 7下不用做
文件系统格式化升级主要是格式化后的大小不够用

如果要被另外的机器使用的话需要安装gluster-cli这个包,然后一样挂载

另外,NFS是集成在glusterfs里面的,不需要配置nfs server 的一些东西 .

