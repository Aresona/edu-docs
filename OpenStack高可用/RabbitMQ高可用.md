# mariadb高可用
## 环境准备
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






