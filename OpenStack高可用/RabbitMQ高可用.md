# mariadb高可用
## 环境准备



# RabbitMQ学习
## Rabbitmq介绍
AMQP，高级消息队列协议，RMQ是一个开源的实现
### RabbitMQ的使用基础
1. Erlang语言包
2. RabbitMQ安装包
### 概念和特性
#### 概念
1. Broker: 简单来说就是消息队列服务器实现
2. Exchange: 消息交换机，它指定消息按什么规则，转发到哪个队列
3. Queue: 消息队列载体，每个消息都会被投入到一个或多个队列
4. Binding: 绑定，它的作用就是把exchange和queue按照路由规则绑定起来
5. Routing Key: 路由关键字，exchange根据这个关键字进行消息投递
6. vhost: 虚拟主机，一个broker里可以开设多个vhost，用作不同用户的权限分离。
7. producer: 消息生产者，就是投递消息的程序。
8. consumer: 消息消费者，就是接受消息的程序。
9. channel: 消息通道，在客户端的每个连接里，可建立多个channel,每个channel代表一个会话任务。

#### 交换机(exchange)
四种类型：

1. direct: 转发消息到routing key指定的队列
2. topic: 按规则转发消息(最灵活)
3. headers: 
4. fanout: 转发消息到所有绑定队列

另：

1. 如果没有队列绑定在交换机上，则发送到该交换机上的消息会丢失。
2. 一个交换机可以绑定多个队列，一个队列可以被多个交换机绑定。
3. topic类型交换器通过模式匹配分析消息的routing-key属性。它将routing-key和binding-key的字符串切分成单词。这些音讯之间用点隔开。它同样也会识别两个符：#匹配0个或者多个单词，*匹配一个单词。
4. 因为交换器是命名褓，声明一个已经存在的交换器，但是试图赋予不同类型是会导致错误。客户端需要删除这个已经存在的交换器，然后重新声明并且赋予新的类型。
5. 交换器的属性：
	1. 持久性： 如果启用，交换器将会在server重启前都有效
	2. 自动删除： 如果启用，那么交换器将会在其绑定的队列被删除掉之后自动删除掉自身。
	3. 惰性： 如果没有声明交换器，那么在执行到使用的时候会导致异常，并不会主动声明。

####　队列(queue)
1. 队列是RabbitMQ内部对象,存储消息。相同属性的queue可以重复定义。
2. 临时队列。channel.queueDeclare(),有时不需要指定队列的名字，并希望断开连接时删除队列。

**队列的属性**
* 持久性： 如果启用，队列将会在server重启前都有效
* 自动删除： 如果启用，那么队列将会在所有的消费者停止使用之后自动删除掉自身。
* 惰性: 如果没有声明队列，那么在执行到使用的时候会导致异常，并不会主动声明。
* 排他性: 如果启用，队列只能被声明它的消费者使用。

#### 特性
##### 高可用性
1. 消息ACK，通知RabbitMQ消息已被处理,可以从内存删除.如果消费者因宕机或链接失败等原因没有发送ACK,则RabbitMQ会将消息重新发送给其他监听在队列的下一个消费者.
2. 消息和队列的持久化。 定义队列时可以指定队列的持久性属性(问： 持久化队列如何删除？)channel.queueDeclare(queuename,,durable=true,false,false,null)；发送消息时可以指定消息持久化属性。这样，即使RabbitMQ服务器重启,也不会丢失队列和消息。
3. publisher confirms提供批量确认消息的方法。
4. master/slave机制，配合Mirrored Queue。Mirrored Queue通过policy和rabbitmqctl设置可以实现。具体可以参考Rabbitmq官方文档。在Mirrored Queue下，无论Producer和Consumer连接那个RabbitMQ服务器，都跟连接同一个RabbitMQ上,消费和生产数据会被同步.

通过命令行或管理插件可以查看哪个slave是同步的

<pre>
rabbitmqctl list_queues name slave_pids synchronised_slave_pids
</pre>
##### 集群
1. 不支持跨网段，因为RabbitMQ底层Erlang，会导致脑裂(Slave Node感觉Master Node死掉了，主Master Node觉得Slave2 Node死掉了，数据无法复制，系统逻辑出现问题)(如需支持，需要shovel或federation插件)
2. 可以随意的动态增加或减少、启动或停止节点，允许节点故障。(但是数据同步会造成Queue服务暂停，所有的Producer和Consumer都被终止)
3. 集群分为RAM节点和DISK节点，一个集群最好至少有一个DISK节点保存集群的状态
4. 集群的配置可以通过命令行，也可以通过配置文件，命令行优先。

##### 设置集群的目的

1. 允许消费者和生产者在RabbitMQ节点崩溃的情况下继续运行运行
2. 通过增加更多的节点来扩展消息通信的吞吐量


##### 集群配置方式
RabbitMQ可以通过三种方法来部署分布式集群系统，分别是：cluster,federation,shovel

**cluster:**

* 不支持跨网段，用于同一个网段内的局域网
* 可以随意的动态增加或者减少
* 节点之间需要运行相同版本的RabbitMQ和Erlang

**federation:**应用于广域网，允许单台服务器上的交换机或队列接收发布到另一台服务器上交换机或队列的消息，可以是单独机器或集群。federation队列类似于单向点对点连接，消息会在聪明队列之间转发任意次，直到被消费者接受。通常使用federation来连接internet上的中间服务器，用作订阅分必消息或工作队列。

**shovel:**连接方式与federation的连接方式类似，但它工作在更低层次。可以应用于广域网。

##### 节点类型

**RAM NODE:**内存节点将所有的队列、交换机、绑定、用户、权限和vhost的元数据定义存储在内存中，好处是可以使得像交换机和队列声明等操作更加的快速

**DISK NODE：**将元数据存储在磁盘中，单节点系统只允许磁盘类型的节点，防止重启RabbitMQ的时候,丢失系统配置信息

**问题说明:**RabbitMQ要求在集群中至少有一个磁盘节点,所有其他节点可以是内存节点,当节点加入或者离开集群时,必须将该变更通知到至少一个磁盘节点.如果集群中唯一的一个磁盘节点崩溃的话,集群仍然可以保持运行,但是无法进行其他操作(增删改查)，直到节点恢复

**解决方案：**设置两个磁盘节点，至少有一个是可用的，可以保存元数据的更改。

##### Erlang Cookie
Erlang cookie是保证不同节点可以相互通信的密钥，要保证集群中的不同节点相互通信必须共享相同的Erlang Cookie。具体的目录存放在 `/var/lib/rabbitmq/.erlang.cookie

说明：这就要从rabbitmqctl命令的工作原理说起，RabbitMQ底层是通过Erlang架构来实现的，所以 `rabbitmqctl`会启动Erlang节点，并基于Erlang节点来使用Erlang系统连接RabbitMQ节点,在连接过程中需要正确的Erlang Cookie和节点名称，Erlang节点通过交换Erlang Cookie以获得认证。

##### 功能和原理
RabbitMQ的Cluster集群模式一般分为两种，普通模式和镜像模式。

**普通模式：**默认的集群模式，对于Queue来说，消息实体只存在于其中一个节点，A、B两个节点仅有相同的元数据，即队列结构。当消息进入A节点的Queue中后，consumer从B节点拉取时，RabbitMQ会临时在A、B间进行消息传输，把A中的消息实体取出并经过B发送给consumer。所以consumer应尽量连接每一个节点，从中取消息。即对于同一个逻辑队列，要在多个节点建立物理Queue。否则无论consumer连接A或B，出口总在A，会产生瓶颈。

该模式存在一个问题就是当A节点故障后，B节点无法取到A节点中还未消费的消息实体。

如果做了消息持久化，那么得等A节点恢复，然后才被消费；如果没有持久化的话，就呵呵了....

**镜像模式：**将需要消费的队列变为镜像队列，存在于多个节点，这样就可以实现RabbitMQ的HA高可用性。作用就是消息实体会主动在镜像节点之间实现同步，而不是像普通模式那样，在consumer消费数据时临时读取。缺点就是，集群内部的同步通读会占用大量的网络带宽。

##### 实现机制

ha-mode | ha-params | 功能
--- | --
all | 空 | 镜像队列将会在整个集群中复制，当一个新的节点加入后，也会在这个节点上复制一份
exactly | count | 镜像队列将会在集群上复制count份，如果集群数量少于count时候，队列会复制到所有节点上，如果大于count集群，有一个节点crash后，新进入节点也不会做新的镜像
nodes | node name | 镜像队列会在node name中复制，如果这个名称不是集群中的一个，这不会触发错误。如果在这个node list中没有一个节点在线，那么这个queue会被声明在client连接的节点

<pre>rabbitmqctl set_policy ha-all '^(?!amq\.).*''{"ha-mode":"all"}'</pre>

###### [基础操作](https://www.rabbitmq.com/management.html#configuration)


<pre>
rabbitmqctl cluster status
rabbitmqctl list_queues name messages_ready messages_unacknowledged
rabbitmqctl status</pre>

##### 镜像模式的脑裂问题

出现脑裂后每个节点的消息都不同步，它自带脑裂的处理机制
<pre>
{cluster_partition_handling, autoheal}
</pre>


## 集群配置

### 节点信息
主机名 | IP |
--- | --
node1 | 192.168.8.146
node2 | 192.168.8.193
node3 | 192.168.8.183
### 主机名解析
<pre>
[root@node3 ~]# cat /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4 node3
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
192.168.8.146	node1
192.168.8.193	node2
192.168.8.183 	node3
</pre>

### 操作
* 安装
<pre>
yum install rabbitmq-server -y
systemctl enable rabbitmq-server
systemctl start rabbitmq-server
rabbitmq-plugins enable rabbitmq_management
</pre>
* 设置Erlang Cookie,将主节点的 `.erlang.cookie` 文件拷贝到另外两个节点

<pre>
cd /var/lib/rabbitmq
scp .erlang.cookie node2:/var/lib/rabbitmq/
scp .erlang.cookie node3:/var/lib/rabbitmq/
</pre>

* 搭建镜像队列集群

<pre>
rabbitmqctl stop
rabbitmq-server -detached
</pre>
> 这里在执行第一条命令的时候可能会失败，需要重启一下 `rabbitmq-server` 服务后再执行
<pre>
rabbitmq-server -detached
Runs RabbitMQ AMQP server in the background.
</pre>


* 组成集群，并设置 `node2` 和 `node3` 为内存节点，在这两个节点执行

<pre>
rabbitmqctl stop_app
rabbitmqctl join_cluster --ram rabbit@node1
rabbitmqctl start_app
</pre>

* 查看 `cluster` 状态
<pre>
[root@node1 ~]# rabbitmqctl set_cluster_name rabbit@node1
Setting cluster name to rabbit@node1 ...
[root@node1 ~]# rabbitmqctl cluster_status
Cluster status of node rabbit@node1 ...
[{nodes,[{disc,[rabbit@node1]},{ram,[rabbit@node3,rabbit@node2]}]},
 {running_nodes,[rabbit@node3,rabbit@node2,rabbit@node1]},
 {cluster_name,<<"rabbit@node1">>},
 {partitions,[]},
 {alarms,[{rabbit@node3,[]},{rabbit@node2,[]},{rabbit@node1,[]}]}]
</pre>

* 配置 `haproxy`

`/etc/haproxy/haproxy.cfg`
<pre>
###############rabbitmq_management-config################
listen rabbitmq_admin 0.0.0.0:15672 
balance roundrobin 
server controller 192.168.8.146:15672 
server network 192.168.8.183:15672 
server compute 192.168.8.194:15672 

##############rabbitmq_cluster-config###############
listen rabbitmq_cluster 0.0.0.0:5672 
option tcplog 
mode tcp 
balance roundrobin 
server controller 192.168.8.146:5672 check inter 5s rise 2 fall 3 
server network 192.168.8.183:5672 check inter 5s rise 2 fall 3 
server compute 192.168.8.194:5672 check inter 5s rise 2 fall 3
systemctl restart haproxy
</pre>

* 修改 `systemd` ，实现服务宕掉后自动重启,在[service]下添加配置`Restart=always`

<pre>
[Unit]
Description=RabbitMQ broker
After=network.target epmd@0.0.0.0.socket
Wants=network.target epmd@0.0.0.0.socket

[Service]
Restart=always
Type=notify
User=rabbitmq
Group=rabbitmq
NotifyAccess=all
TimeoutStartSec=3600
WorkingDirectory=/var/lib/rabbitmq
ExecStart=/usr/lib/rabbitmq/bin/rabbitmq-server
ExecStop=/usr/lib/rabbitmq/bin/rabbitmqctl stop

[Install]
WantedBy=multi-user.target
</pre>
* 验证集群是否成功

在主节点上，通过下列命令杀死 `rabbitmq` 进程
<pre>
ps -ef|grep rabbitmq|awk '{print $2}' | xargs kill -9
</pre>
在其它节点上查看rabbitmq运行状态
<pre>
[root@node2 rabbitmq]# rabbitmqctl cluster_status
Cluster status of node rabbit@node2 ...
[{nodes,[{disc,[rabbit@node1]},{ram,[rabbit@node3,rabbit@node2]}]},
 {running_nodes,[rabbit@node3,rabbit@node2]},
 {cluster_name,<<"rabbit@node1">>},
 {partitions,[]},
 {alarms,[{rabbit@node3,[]},{rabbit@node2,[]}]}]
</pre>

* 修复

在重新把该节点加入集群的时候需要注意，因为 `haproxy` 已经监听了地址，所以需要先把 `haproxy` 关掉后，再通过 `rabbitmq-server -detached` 命令启动 `rabbitmq-server` ，然后再启动haproxy