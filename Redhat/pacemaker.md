三个节点都执行
<pre>
yum install nginx -y
yum install fence-agents-all -y
yum install pcs -y
systemctl start pcsd
</pre>
配置互信及时间同步，并关闭防火墙等。
<pre>
passwd hacluster
</pre>
集群各节点间进行认证
<pre>
pcs cluster auth node1 node2 node3
</pre>
创建并启动集群
<pre>
pcs cluster setup --start --name my_cluster node1 node2 node3
</pre>

关闭stonith设备
<pre>
[root@host28 ~]# crm_verify -L -V
   error: unpack_resources:	Resource start-up disabled since no STONITH resources have been defined
   error: unpack_resources:	Either configure some or disable STONITH with the stonith-enabled option
   error: unpack_resources:	NOTE: Clusters with shared data need STONITH to ensure data integrity
Errors found during check: config not valid
[root@host28 ~]# pcs property set stonith-enabled=false
[root@host28 ~]# crm_verify -L -V
</pre>

配置VIP
<pre>
pcs resource create VIP ocf:heartbeat:IPaddr2 ip=10.20.0.31 cidr_netmask=24 op monitor interval=30s
</pre>
