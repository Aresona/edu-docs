# OVS

Neutron服务也支持`L2 Agent`使用OVS来做，OpenStack也通过`ML Plugin`实现了既支持linuxbridge，也支持OVS。

## 服务端需要的操作
### 控制节点
这里以创建VLAN为例来配置

`neutron.conf`
<pre>
core_plugin = ml2
</pre>

`ml2_conf.ini`
<pre>
[DEFAULT]
type_drivers = flat,local,vlan,gre,vxlan,geneve
tenant_network_types = flat,vlan,local
mechanism_drivers = linuxbridge,openvswitch
[ml2_type_vlan]
network_vlan_ranges = virtual1:3001:4000
</pre>


### 计算节点
`nova.conf`
<pre>
linuxnet_interface_driver=nova.network.linux_net.LinuxOVSInterfaceDriver
</pre>

`openvswitch`
<pre>
bridge_mappings = virtual1:br-eth1
</pre>

命令行操作
<pre>
systemctl start openvswitch
ovs-vsctl add-br br-eth1
ovs-vsctl add-port br-eth1 em2
systemctl restart neutron-openvswitch-agent.service
</pre>

另外因为要配置VLAN，所以与em2网卡相连接的交换机端口一定要是trunk口。
