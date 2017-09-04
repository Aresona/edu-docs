# 调整MTU
这个操作需要多方面配合


## 服务器
<pre>
ip link set bond2 mtu 9000
ip link ensp4s1 mtu 9000
ip link ensp5s1 mtu 9000
cat /proc/net/bonding/bond2
</pre>
后期补充永久修改的方法
## 交换机

在ceph调优中可能会用到这个技术，目前在ceph调优中，为了提高小文件写的性能，调整cluster网络的mtu为9000，在调整后需要重启osd全部服务使生效

<pre>
systemctl restart ceph-osd.target
</pre>