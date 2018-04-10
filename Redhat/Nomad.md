# Nomad 与 k8s对比
1. k8s的目标是提供运行docker所需要的所有的功能，包括集群管理、调度、服务发现、监控、密钥管理;
2.  `Nomad` 的目标是提供集群管理和调度，并且只针对linux，它结合consul来提供服务发现功能，结合Vault提供密钥管理
3.  k8s只针对容器，而consul针对的范围更广一些，包括虚拟化、容器化和独立的应用。
4.  k8s复杂，nomad简单，它只包括一个二进制文件，里面包含了客户端与服务端，并且不需要另外的服务提供协调和存储。nomad将轻量级的资源管理器和复杂的调度器组合到一个系统中。nomad是分布式的、高可用的、易操作的系统。
5.  




常见命令

<pre>
nomad plan *.hcl
nomad run *.hcl
nomad status
nomad status topo
nomad status -short topo
nomad alloc-status xxx
nomad node-status xxx
nomad node-status -self
nomad status
nomad node-status --allocs
nomad server-members
</pre>

服务管理
<pre>
nomad agent -dev
nomad agent -config=/etc/nomad
</pre>

服务管理
<pre>
nomad stop neutron-agents
nomad run /etc/kolla/nomad/neutron-agents.hcl
</pre>

# consul
consul members看到的不是实时信息，如果想要看到比较实时的信息，需要使用HTTP API，而不是gossip协议。

<pre>
curl localhost:8500/v1/catalog/nodes
consul-cli kv read /templates/neutron/ml_conf.ini.ctmpl
consul-cli kv read templates/neutron/ml2_conf.ini.ctmpl
</pre>

参考文档：

AWStack Neutron多外部网络配置.pdf

容器内调试：http://wiki.corp/pages/viewpage.action?pageId=42074640

容器启动运行的命令是kolla_start,一般会在该脚本里面调用/run_command命令来作为容器的启动命令，另外容器还有渲染的功能，一般使用了渲染功能的文件需要通

过consul-cli kv write的方式修改，因为直接修改容器里面的文件会被该功能的默认配置覆盖。

收集日志的两种方式：

1. 本地默认路径
2. alloc/xxxxx/alloc/logs
