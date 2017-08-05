### 操作思路
下面操作用于不满足当前分区，并且当前分区是通过LVM实现的时，手动修改分区。整体思路是先备份数据，然后通过LVM相关命令调整分区，最后把数据拷贝回来。

### 操作命令集合
<pre>
cp -rf /home/awcloud/ /opt
umount /home/
lvremove /dev/mapper/centos-home 
lvextend -l +100%FREE /dev/mapper/centos-root
xfs_growfs /dev/mapper/centos-root
cd /home/
cp -rf /opt/awcloud/ .
chown -R awcloud.awcloud awcloud
sed -i '/centos-home/d' /etc/fstab
</pre>
### 操作记录 
<pre>
[awcloud@node1 ~]$ df -h
Filesystem               Size  Used Avail Use% Mounted on
/dev/mapper/centos-root   50G  1.7G   49G   4% /
devtmpfs                  48G     0   48G   0% /dev
tmpfs                     48G     0   48G   0% /dev/shm
tmpfs                     48G   18M   48G   1% /run
tmpfs                     48G     0   48G   0% /sys/fs/cgroup
/dev/sda1                494M  125M  370M  26% /boot
/dev/mapper/centos-home  1.1T   33M  1.1T   1% /home
tmpfs                    9.5G     0  9.5G   0% /run/user/0
tmpfs                    9.5G     0  9.5G   0% /run/user/1000
[root@node1 ~]# cp -rf /home/awcloud/ /opt
[root@node1 ~]# umount /home/
[root@node1 ~]# lvremove /dev/mapper/centos-home 
Do you really want to remove active logical volume home? [y/n]: y
  Logical volume "home" successfully removed
[root@node1 ~]# lvextend -l +100%FREE /dev/mapper/centos-root
  Size of logical volume centos/root changed from 50.06 GiB (12815 extents) to 1.09 TiB (284714 extents).
  Logical volume root successfully resized.
[root@node1 awcloud]# xfs_growfs /dev/mapper/centos-root 
meta-data=/dev/mapper/centos-root isize=256    agcount=4, agsize=3276800 blks
         =                       sectsz=4096  attr=2, projid32bit=1
         =                       crc=0        finobt=0
data     =                       bsize=4096   blocks=13107200, imaxpct=25
         =                       sunit=0      swidth=0 blks
naming   =version 2              bsize=4096   ascii-ci=0 ftype=0
log      =internal               bsize=4096   blocks=6400, version=2
         =                       sectsz=4096  sunit=1 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0
data blocks changed from 13107200 to 291547136
[root@node1 awcloud]# df -h
Filesystem               Size  Used Avail Use% Mounted on
/dev/mapper/centos-root  1.1T  1.7G  1.1T   1% /
devtmpfs                  48G     0   48G   0% /dev
tmpfs                     48G     0   48G   0% /dev/shm
tmpfs                     48G   18M   48G   1% /run
tmpfs                     48G     0   48G   0% /sys/fs/cgroup
/dev/sda1                494M  125M  370M  26% /boot
tmpfs                    9.5G     0  9.5G   0% /run/user/0
[root@node1 ~]# cd /home/
[root@node1 home]# ls
[root@node1 home]# cp -rf /opt/awcloud/ .
[root@node1 home]# chown -R awcloud.awcloud awcloud
</pre>


