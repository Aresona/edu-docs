## Centos7下挂载磁盘为xfs格式

* 找到需要挂载的磁盘

<pre>
ls /dev/sd*
</pre>

* 格式化该磁盘

<pre>
mkfs.xfs /dev/sdb
</pre>

* 创建挂载点

<pre>
mkdir /data1
</pre>

* 挂载磁盘到挂载点

<pre>
mount -t xfs /dev/sdb /data1
</pre>

* 配置开机自动挂载
	* 查看该磁盘的UUID并加入开机启动文件 `/etc/fstab` 下
<pre>
blkid /dev/sdb
/dev/sdb: UUID="1992ae18-d8e2-446c-be54-cb27c645df64" TYPE="xfs" 
echo "UUID=1992ae18-d8e2-446c-be54-cb27c645df64 /data1		  xfs 	  defaults	  0 0" >> /etc/fstab
</pre>

 
