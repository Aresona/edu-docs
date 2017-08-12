


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