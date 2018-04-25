


### 通过修改文件修改crushmap
<pre>
ceph osd getcrushmap > 1
crushtool -d 1 -o 2
crushtool -c 2 -o map
ceph osd setcrushmap -i map
</pre>

###通过命令行修改crush(增，移动)
<pre>
ceph osd crush add-bucket rack1 rack
ceph osd crush add-bucket rack2 rack
ceph osd crush move test1 rack=rack1
ceph osd crush move test2 rack=rack2
ceph osd crush move rack1 root=default
ceph osd crush move rack2 root=default
ceph osd crush rule create-simple racky default rack
ceph osd pool set rbd crush_ruleset 3
</pre>

### 跟踪落盘情况
<pre>
osdmaptool  --test-map-object rbd_data.245311238e1f29.0000000000000de6 /rados/osdmap --pool sas-volumes
</pre>
### 查看所有pool
<pre>
lspools:
rados lspools
ceph osd lspools
</pre>

### 取得索引
<pre>
rados -p sas-volumes get rbd_directory rbd_directory.txt
</pre>

### 查看wathcers
<pre>
rbd status sas-volumes/host28    一个watcher代表一个map设备
</pre>

### 生产环境加入三个节点时的记录
<pre>
[root@host70 ~]# ceph osd getcrushmap > mycrush
got crush map from osdmap epoch 4790
[root@host70 ~]# crushtool -d mycrush -o mycrush.txt
[root@host70 ~]# vim mycrush.txt 
[root@host70 ~]# ceph osd setcrushmap mycrush.txt
Invalid command:  unused arguments: [u'mycrush.txt']
osd setcrushmap :  set crush map from input file
Error EINVAL: invalid command
[root@host70 ~]# crushtool -c mycrush.txt -o mycrush1
[root@host70 ~]# ceph osd setcrushmap -i mycrush1
set crush map
</pre>


### 打入流量到CEPH集群：
<pre>
[root@host30 ~]# ceph osd pool create sas-test 2048 2048 sas
pool 'sas-test' created
[root@host30 ~]# ceph osd pool set sas-test size 3
set pool 103 size to 3
ansible test2,osds -m shell -a 'rbd create `hostname` -p sas-test --size 20T'
ansible test2,osds -m shell -a 'rbd map `hostname` -p sas-volumes'
ansible test2,osds -a 'rbd showmapped'
ansible osds,test2 -m shell -a 'rbd export e9653a19-a0fa-437c-991e-0b65afa00b1b -p images image-test'
ansible test2,osds -m shell -a 'for ((i=0;i<24300;++i));do cat /root/image-test;done |dd of=/dev/rbd1 bs=4M status=progress'
</pre>
### 查看PG分布
<pre>
ceph pg dump|less -S
</pre>

### 日志相关
<pre>
ceph daemon osd.183 config show |less    ## 查看日志
ceph daemon osd.183 dump_opss_in_flight
ceph daemon /var/run/ceph/ceph-osd.asok config show   查看日志
ceph tell 
</pre>

### 用zcat命令查看gzip压缩后的文件
<pre>
zcat xx.gz
</pre>

### 查看osd性能
<pre>
ceph osd perf |sort -nk3 |less
</pre>

ceph osd perf |sork -nk3|less



### 查看osd状态
<pre>
ceph -s
ceph osd stat
ceph osd tree
ceph osd dump
</pre>
> osd状态有两种，一种是UP，一种是DOWN，UP就是后端启动并且能响应，DOWN就表示不启动或不响应，其它的OSD或MON不能收到任何heatbeat信息;从另一角度来说，还有两种状态，一种是IN，一种是OUT：IN表示OSD参与数据存放，OUT表示不参与数据存放;另外当经历一些时间短的failure的时候，节点会在down的时候保持在IN状态5分钟（默认），5分钟后才会改成OUT状态
<pre>
ceph osd out osd.xxx
</pre>
### 查看PG信息
<pre>
ceph pg dump
</pre>

### [踢出废弃的OSD](http://www.zphj1987.com/2016/01/12/%E5%88%A0%E9%99%A4osd%E7%9A%84%E6%AD%A3%E7%A1%AE%E6%96%B9%E5%BC%8F/)
方法一：
<pre>
systemctl stop ceph-osd@xx
ceph osd out osd.xx
ceph osd crush remove osd.xx
ceph osd rm osd.xx
ceph auth del osd.xx
</pre>
方法二：
<pre>
ceph osd crush reweight osd.xx 0.1
systemctl stop ceph-osd@xx
ceph osd out osd.xx
ceph osd crush remove osd.xx
ceph osd rm osd.xx
ceph auth del osd.xx
</pre>


<pre>
systemctl stop ceph-osd.target # all osd
systemctl list-units -a |grep ceph|grep mount|grep var|sed 's/\\/\\\\/g'|awk '{print $1}'|xargs systemctl stop   # 停所有 mount 服务
systemctl list-units -a |grep ceph|grep mount|grep var|sed 's/\\/\\\\/g'|awk '{print $1}'|xargs systemctl disable 

for i in sd{b..l}; do ceph-disk trigger /dev/${i}1; done    # 启动正常的
find /var/lib/ceph/osd/ -maxdepth 2 -name journal |xargs readlink  |xargs readlink |sort
</pre>

### ceph-disk
<pre>
prepare             Prepare a directory or disk for a Ceph OSD
activate            Activate a Ceph OSD
activate-lockbox    Activate a Ceph lockbox
activate-block      Activate an OSD via its block device
activate-journal    Activate an OSD via its journal device
activate-all        Activate all tagged OSD partitions
list                List disks, partitions, and Ceph OSDs
suppress-activate   Suppress(压制) activate on a device (prefix)
unsuppress-activate
                    Stop suppressing activate on a device (prefix)
deactivate          Deactivate a Ceph OSD
destroy             Destroy a Ceph OSD
zap                 Zap/erase/destroy a device's partition table (and
                    contents)
trigger             activate any device (called by udev)
</pre>


### 重新构建OSD
<pre>
umount /dev/sdj1; ceph-disk destroy /dev/sdj1 --zap
ceph-disk prepare /dev/sdj
ceph-disk prepare /dev/sdd /dev/sdb1  (数据盘/日志盘)
mount|grep sdj
ceph-disk trigger /dev/sdm1
</pre>

<pre>
[root@host72 ~]# ceph-disk destroy -h
usage: ceph-disk destroy [-h] [--cluster NAME] [--destroy-by-id <id>]
                         [--dmcrypt-key-dir KEYDIR] [--zap]
                         [PATH]

Destroy the OSD located at PATH. It removes the OSD from the cluster,
the crushmap and deallocates the OSD id. An OSD must be down before it
can be destroyed.

positional arguments:
  PATH                  path to block device or directory

optional arguments:
  -h, --help            show this help message and exit
  --cluster NAME        cluster name to assign this disk to
  --destroy-by-id <id>  ID of OSD to destroy
  --dmcrypt-key-dir KEYDIR
                        directory where dm-crypt keys are stored (If you don't
                        know how it work, dont use it. we have default value)
  --zap                 option to erase data and partition
</pre>


# 脚本
## 脚本一
<pre>
[root@host72 ~]# cat b.sh 
#!/bin/sh

for i in sd{j..m}; do 
umount /dev/${i}1
umount /dev/${i}2
sleep 1

ceph-disk destroy  /dev/${i}1
ceph-disk destroy  /dev/${i}2


ceph-disk zap /dev/$i

ceph-disk prepare /dev/${i}


done
</pre>

## 脚本二
<pre>
#!/bin/sh

for i in sd{l..m}; do 
umount /dev/${i}1
umount /dev/${i}2
sleep 1

ceph-disk destroy  /dev/${i}1
ceph-disk destroy  /dev/${i}2


ceph-disk zap /dev/$i

sgdisk -n 3:0:+10G /dev/$i  --typecode=3:45b0969e-9b03-4f30-b4c6-b4b80ceff106 --change-name=3:"ceph journal"
sgdisk -n 4:0:+10G /dev/$i --typecode=4:45b0969e-9b03-4f30-b4c6-b4b80ceff106 --change-name=4:"ceph journal"

sgdisk -n 1:0:+360G /dev/$i --typecode=1:89c57f98-2fe5-4dc0-89c1-f3ad0ceff2be --change-name=1:"ceph data"
sgdisk -n 2:0:0 /dev/$i --typecode=2:89c57f98-2fe5-4dc0-89c1-f3ad0ceff2be --change-name=2:"ceph data"



done

#sgdisk --typecode=1:4fbd7e29-9d25-41b8-afd0-062c0ceff05d -- /dev/sdj 
#sgdisk --typecode=2:4fbd7e29-9d25-41b8-afd0-062c0ceff05d -- /dev/sdj 
#sgdisk --typecode=3:45b0969e-9b03-4f30-b4c6-b4b80ceff106 -- /dev/sdj
#sgdisk --typecode=4:45b0969e-9b03-4f30-b4c6-b4b80ceff106 -- /dev/sdj

for i in sd{l..m}; do 

ceph-disk prepare /dev/${i}1 /dev/${i}3 
ceph-disk prepare /dev/${i}2 /dev/${i}4 

sgdisk --typecode=1:4fbd7e29-9d25-41b8-afd0-062c0ceff05d -- /dev/${i}
sgdisk --typecode=2:4fbd7e29-9d25-41b8-afd0-062c0ceff05d -- /dev/${i}

done
</pre>
