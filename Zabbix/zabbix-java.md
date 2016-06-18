**添加一台主机到zabbix**

1. 安装zabbix-agent
2. 修改配置文件/etc/zabbix/zabbix-agnetd.conf(修改Server为zabbix服务端)
3. 启动zabbix-agent
4. web配置
###### web配置（通过克隆的方式）

主机 --> 全部克隆 --> 修改 --> templates选 OS Linux

**修改maps**

* 修改lable
<pre>
{HOST.NAME}
{HOST.IP}
</pre>
* 在两台主机间加链接并显示之间的网卡流量
<pre>
{linux-node1.oldboyedu.com:net.if.out[eth0].last(0)}
</pre>


### 报警

> 报警的本质是事件通知

#### 事件通知的几个方面

1. 通知啥（Action）
2. 什么情况下通知(conditions)
3. 怎么通知(operations)
4. 通过什么途径发送(media types)
5. 发送给谁(users-Media)
6. 通知升级
7. 发送目标

设置报警需要设置三个地方：Aactions   Media types   Users-Media

##### 完整的告警流程

> 模拟新人入职

1. 创建用户组
	1. ops  权限(可以添加读写，只读)   权限只能按用户组分配

2. 添加用户
3. 设置报警媒介
4. Action

> 如果新加一台机器，又新加了一个用户，这时要看一下这个用户是不是有这些机器的权限。
> 添加新主机后，要确认权限分配


## 生产案例实战 

架构图见doc

> 无论再小的架构，也要先规划

### 项目规划
* 主机分组 
	* 交换机
	* Nginx
	* Tomcat
	* MySQL

* 监控对象识别
	1. 使用SNMP监控交换机
	2. 使用IPMI监控服务器硬件 
	3. 使用Agent监控服务器
	4. 使用JMX监控JAVA应用 
	5. 监控MySQL
	6. 监控WEB状态
	7. 监控Nginx状态

### 实施监控

###### SNMP监控
* 交换机上开启SNMP
	
<pre>
snmp-server community public ro
</pre>

* 在zabbix上添加监控

可以使用GNS3来模拟网络设备

<pre>
configure    host    create host   switch-node1     Newo Group(switch-group)    

SNMP interfaces   port
</pre>
 
* 关联监控模板（SNMP Device,可以监控防火墙、路由器、交换机）
* 设置SNMP团体名称(Macros   {$SNMP_COMMUNITY} ＝ oldboyedu

> 为什么要加宏？  因为模板里面的items里面需要用到这个变量

添加完毕后它会做端口的自动发现，这里有一些截图，每个端口都会有触发器，并且可以看到每个端口的一些流量图


###### IPMI监控

* web配置IPMI监控项，加上IP地址和用户名、密码（IPMI太容易超时了，获取不到值，并且性能也有问题，**个人建议使用自定义脚本来创建item,本地执行ipmitool命令来获取数据**）

*常用命令*

	ipmitool set list        看日志
	
	ipmitool sensor list	看温度 	

> 另外就算用了IPMI接口，它自带的IPMI的模板不好使，对不上，很多值获取不到，每台机器可能都不一样。

###### 使用Agent监控服务器

###### 使用JMX监控JAVA

[实现原理](http://caisangzi.blog.51cto.com/6387416/1301682)

zabbix是使用C++写的，cacti是通过php去采集数据的

JMX三种监控类型：1.无密码认证  2. 用户名密码认证，  3. ssl  

做完之后通过jconsole连上去看一下

***Zabbix java Gateway***

zabbix默认提供了一个能监控JAVA应用的JMX接口（zabbix java gateway）,它就是用java写的

安装java-geteway,可以理解成一个代理，跟zabbix server完全没有关系

监控java应用的原理 ，如图在doc

它不存任何的数据，它就是一个代理

安装及配置文件路径

<pre>
yum install -y zabbix-java-gateway java-1.8.0
/etc/zabbix/zabbix_java_gateway.conf
</pre>

其实默认是不需要修改的，

监听IP地址，PORT、PID、START_POLLERS,根据有多少JAVA应用来设置、TIMEOUT(经验值，1－30）

    systemctl start zabbix-java-gateway.service

装一个实现tab实例命令的包
<pre>
yum install bash-completion
</pre>
启动成功后会监控一个10052的端口，它是一个java应用

配置/etc/zabbix/zabbix_server.conf来指定gateway的地址

	JavaGateway=192.168.56.11
	StartJavaPollers=5
	systemctl restart zabbix-server


***Install Tomcat***

<pre>
cd /usr/local/src
wget http://mirrors.tuna.tsinghua.edu.cn/apache/tomcat/tomcat-8/v8.0.36/bin/apache-tomcat-8.0.36.tar.gz
tar zxf apache-tomcat-8.0.36.tar.gz 
mv apache-tomcat-8.0.36 /usr/local/
ln -s /usr/local/apache-tomcat-8.0.36/ /usr/local/tomcat
/usr/local/tomcat/bin/startup.sh
netstat -lntup|grep 8080
</pre>

***remote monitor***

vim /usr/local/tomcat/bin/catalina.sh
	   CATALINA_OPTS="$CATALINA_OPTS -Dcom.sun.management.jmxremote
  -Dcom.sun.management.jmxremote.port=8888
  -Dcom.sun.management.jmxremote.ssl=false
  -Dcom.sun.management.jmxremote.authenticate=false
  -Djava.rmi.server.hostname=192.168.56.12"

重启tomcat
shutdown.sh
startup.sh

这个模板自带的模块有很多没用的，需要自己看一下。jconsole


##### 手动检测监控状态

<pre>
yum install -y zabbix-get
zabbix_get -s 192.168.56.12 -k jmx["java.lang:type=Runtime",Uptime]
</pre>



安装java
https://java.com/zh_CN/download/chrome.jsp


## 生产角度

1. 开启Nginx监控
2. 编写脚本来进行数据采集
3. 设置用户自定义参数
4. 重启zabbix-agent
5. 添加item
6. 创建图形
7. 创建触发器
8. 创建模板

这时有一个问题就是如果多加一台机器的话就需要再来一遍，所以 这里要学会创建模板

模板里面包含什么呢？图形、item、触发器、screen等。

看一下监控插件 (补笔记)

zabbix_linux_plugin.sh
修改nginx配置文件显示状态，并限制只有本地能够访问

	location /nginx_status {
	            stub_status on;
	            access_log  off;
	            allow 127.0.0.1;
	            deny all;
	        }
编写自定义key并测试访问结果
<pre>
[root@linux-node1 zabbix_agentd.d]# cat linux.conf 
UserParameter=linux_status[*],/etc/zabbix/zabbix_agentd.d/zabbix_linux_plugin.sh "$1" "$2" "$3"
systemctl restart zabbix-agent.service 
[root@linux-node1 zabbix_agentd.d]# zabbix_get -s 192.168.56.11 -k linux_status[nginx_status,8080,active]
1
</pre>

加一个永久性的模板   

加item  加应用（给item分组）    加图形



## 触发器

讲了添加一个触发器和修改默认模板触发器的值


## 自定义脚本报警


pymail.py
1. 脚本存放地址：
zabbix-server : AlertScriptsPath=/usr/lib/zabbix/alertscripts
2. 支持三个参数（收件人、主题、内容）
3. 执行权限
4. Web界面添加
5. 修改Action


如阿里大鱼短信通道，验证码，手机通知，广告等都是通过短信通道来实现的，而且还有规范，工信部 也就是说必须有一个签名，而且得有模板，短信模板也要备案，多一个字都发不出去，也有一些通道没有定义那么严格，就可以来做我们的报警
一条4.5分左右 

可以注册一个，一般有HTTP的API，所以在脚本里面写一个CURL就可以了

<pre>
curl -X POST 'http://gw.api.taobao.com/router/rest' \
-H 'Content-Type:application/x-www-form-urlencoded;charset=utf-8' \
-d 'app_key=12129701' \
-d 'format=json' \
-d 'method=alibaba.aliqin.fc.sms.num.send' \
-d 'partner_id=apidoc' \
-d 'sign=98C9750B4FFCD0BCEF7805FAA201391A' \
-d 'sign_method=hmac' \
-d 'timestamp=2016-06-18+15%3A06%3A21' \
-d 'v=2.0' \
-d 'extend=123456' \
-d 'rec_num=13000000000' \
-d 'sms_free_sign_name=%E9%98%BF%E9%87%8C%E5%A4%A7%E9%B1%BC' \
-d 'sms_param=%7B%5C%22code%5C%22%3A%5C%221234%5C%22%2C%5C%22product%5C%22%3A%5C%22alidayu%5C%22%7D' \
-d 'sms_template_code=SMS_585014' \
-d 'sms_type=normal'
</pre>


亿美软通   阿里大鱼

短信内容 
L: {TRIGGER.SEVERITY}

 {ITEM.NAME1} ({HOST.NAME1}:{ITEM.KEY1}): {ITEM.VALUE1}

winxin.qq.com

公众平台

个人服务号不允许直接给关注的用户发送消息

让公司注册微信企业号，然后直接CURL过去就可以发了，有一个KEY，但是

**所有业务类的报警全是走的邮件，而且只是上班期间发，运维的话就发短信**

叮叮  QQ  飞信  

**不管发什么，上面这三条留着，也就是记录发送的日志**


####### MySQL

使用percona监控插件监控MySQL

zabbix中真正监控MySQL的时候用的是percona的监控脚本

percona.com

[perona](https://www.percona.com/doc/percona-monitoring-plugins/1.1/zabbix/index.html#installation-instructions)


它是从cacti来改过来的，也有一整套的zabbix模板

https://www.percona.com/doc/percona-server/5.6/installation/yum_repo.html
<pre>
yum install http://www.percona.com/downloads/percona-release/redhat/0.1-3/percona-release-0.1-3.noarch.rpm
yum install percona-zabbix-templates php php-mysql -y
cp /var/lib/zabbix/percona/templates/userparameter_percona_mysql.conf /etc/zabbix/zabbix_agentd.d/
systemctl restart zabbix-agent.service
</pre>

1. php脚本用来数据采集
2. shell  调用这个php
3. zabbix配置文件
4. zabbix模板文件

创建zabbix监控专用用户

[root@linux-node1 scripts]# ./get_mysql_stats_wrapper.sh gm
1


<pre>
[root@linux-node1 zabbix_agentd.d]# rpm -ql percona-zabbix-templates
/var/lib/zabbix/percona
/var/lib/zabbix/percona/scripts
/var/lib/zabbix/percona/scripts/get_mysql_stats_wrapper.sh
/var/lib/zabbix/percona/scripts/ss_get_mysql_stats.php
/var/lib/zabbix/percona/templates
/var/lib/zabbix/percona/templates/userparameter_percona_mysql.conf
/var/lib/zabbix/percona/templates/zabbix_agent_template_percona_mysql_server_ht_2.0.9-sver1.1.6.xml
</pre>

## web监控

默认自带
前面在56.12上启动了一个tomcat,现在就监控这个
configure  hosts
它不依赖于agent

打印机也可以监控

树没派



当监控的主机越来越多的时候就会出现一些问题

如
性能瓶颈（怎么看能不能搞住   administratior--queue,看这个值，如果延时太多就是有问题）

zabbix可以轻松解决这两个问题，而nagios不太好解决

1. 监控主机多，性能跟不上，延迟大
2. 多机房，防火墙的因素

对于第一点来说

默认server去轮询问客户机，server就会很繁忙，所以要提到zabbix的监控模式，默认是被动模式，还有一个是主动模式

针对Agent来说
1. 被动模式(点开item  type)
2. 主动模式（Active）

> 当监控主机超过300+，建议使用主动模式，这只是一个经验值

条件
1. queue里有大量延时的item
2. 当监控主机超过300+

##### 把node2改成主动模式

######### 配置客户端
<pre>
vim /etc/zabbix/zabbix_agnet.conf
ServerActive=192.168.56.11 （如果跨机房，可以改成域名）
StartAgents=0
Hostname=linx-node2.oldboyedu.com 
[root@linux-node2 ~]# grep '^[a-Z]' /etc/zabbix/zabbix_agentd.conf 
PidFile=/var/run/zabbix/zabbix_agentd.pid
LogFile=/var/log/zabbix/zabbix_agentd.log
LogFileSize=0
DebugLevel=3
StartAgents=0
ServerActive=192.168.56.11
Hostname=linux-node2.oldboyedu.com
Include=/etc/zabbix/zabbix_agentd.d/
systemctl restart zabbix-agent
</pre>

这里agent起来连端口都不监控了，这样防火墙也好做

########  配置服务器端

就是在WEB界面添加active的items tmeplates 和hosts

## zabbix Proxy

不仅仅解决多主机的问题，还解决多机房的问题

它是一个代理，代替Zabbix Server去获取内容，存在本地，然后再发给server

zabbix-server    -->  zabbix proxy  -- zabbix agent

www.zabbix.com/documentation/3.0/distributed_monitoring

特征：

不做告警通知，没有WEB,没有触发器，可以理解为纯收集，并且它是需要数据库的，所以它不能跟server装在同一台数据库上，因为它的一些表名是一样的

######## 安装proxy

	yum install -y zabbix-proxy zabbix-proxy-mysql mariadb-server
	systemctl start mariadb
	mysql
	create database zabbix_proxy character set utf8;
	grant all on zabbix_proxy.* to zabbix_proxy@localhost identified by 'zabbix_proxy';
	cd /usr/share/doc/zabbix-proxy-mysql-3.0.3
	zcat schema.sql.gz | mysql -uzabbix_proxy -p zabbix_proxy

改配置文件


	[root@linux-node2 ~]# grep '^[a-Z]' /etc/zabbix/zabbix_proxy.conf 
	Server=192.168.56.11
	Hostname=zabbix-proxy
	LogFile=/var/log/zabbix/zabbix_proxy.log
	LogFileSize=0
	PidFile=/var/run/zabbix/zabbix_proxy.pid
	DBName=zabbix_proxy
	DBUser=zabbix_proxy
	DBPassword=zabbix_proxy
	SNMPTrapperFile=/var/log/snmptrap/snmptrap.log
	Timeout=4
	ExternalScripts=/usr/lib/zabbix/externalscripts
	LogSlowQueries=3000



	[root@linux-node2 ~]# grep '^[a-Z]' /etc/zabbix/zabbix_proxy.conf 
	Server=192.168.56.11
	Hostname=zabbix-proxy
	LogFile=/var/log/zabbix/zabbix_proxy.log
	LogFileSize=0
	PidFile=/var/run/zabbix/zabbix_proxy.pid
	DBHost=localhost
	DBName=zabbix_proxy
	DBUser=zabbix_proxy
	DBPassword=zabbix_proxy
	SNMPTrapperFile=/var/log/snmptrap/snmptrap.log
	Timeout=4
	ExternalScripts=/usr/lib/zabbix/externalscripts
	LogSlowQueries=3000


	systemctl start zabbix-proxy
	netstat -lntup
	tcp        0      0 0.0.0.0:10051           0.0.0.0:*               LISTEN      18144/zabbix_proxy 



web界面添加

administration   proxies   create 

zabbix-proxy

找一台机器做实验

monitor by proxy

zabbix-agent.conf
ServerActive=192.168.56.12

restart zabbix-agent 

上面就是分布式监控里面的两种解决方式

生产中最大的问题其实是数据库的问题，而且有几张表会特别的大，有几点是可以做的，如SSD（不太贵了）、定期删除一些数据（要求保留三年的数据，但今年肯定不会查去年的，但是需要有，可以一年一个库）、做表分区、定期删除老数据，做表优化、让每个表一个数据文件（innodb）。


## 自动化监控

需要不停地点鼠标，所以要做自动化的监控

分类：（所有的自动化都可以分为两种）

1. 自动注册
2. 主动发现

自动注册就是我起来了就告诉老大，我要当你小弟

主动发现就是我主动发现你。

这两种方法zabbix都支持

* 自动注册
	* zabbix agent自动添加
2. 主动发现
	1. 自动发现discover
	2. zabbix api


### 自动发现（注册）

server是谁，我是谁，我有什么特征（方便配置模板）

	vim /etc/zabbix/zabbix_agentd.conf
	[root@linux-node2 ~]# grep '^[a-Z]' /etc/zabbix/zabbix_agentd.conf 
	PidFile=/var/run/zabbix/zabbix_agentd.pid
	LogFile=/var/log/zabbix/zabbix_agentd.log
	LogFileSize=0
	StartAgents=0
	ServerActive=192.168.56.11
	Hostname=linux-node2.oldboyedu.com
	HostMetadataItem=system.uname
	Include=/etc/zabbix/zabbix_agentd.d/
	systemctl restart zabbix-agent


configure  action  auto registration   create action




#### 自动 发现

configure   discovery
文档： network discovery

创建一个discovery

改配置文件

	[root@linux-node2 ~]# grep '^[a-Z]' /etc/zabbix/zabbix_agentd.conf 
	PidFile=/var/run/zabbix/zabbix_agentd.pid
	LogFile=/var/log/zabbix/zabbix_agentd.log
	LogFileSize=0
	Server=192.168.56.11
	StartAgents=3
	Hostname=linux-node2.oldboyedu.com
	HostMetadataItem=system.uname
	Include=/etc/zabbix/zabbix_agentd.d/

生产中有坑，一般不用，link的不是特别准确，还有就是VIP的问题，一般用API

## API（服务化）

https://www.zabbix.com/documentation/3.0/manual/discovery/network_discovery**

两个功能，要么查询，要么管理

使用
发送POST请求到

	curl -s -X POST -H 'Content-Type:application/json' -d '
	{
	    "jsonrpc": "2.0",
	    "method": "user.login",
	    "params": {
	        "user": "zhangsan",
	        "password": "123456"
	    },
	    "id": 1
	}' http://192.168.56.11/zabbix/api_jsonrpc.php | python -m json.tool
	

返回：
	{
	    "id": 1,
	    "jsonrpc": "2.0",
	    "result": "77cec95b062cd2ab54783ef45035959c"
	}

通过cookie显示所有的主机

	curl -s -X POST -H 'Content-Type:application/json' -d '	
	{
	    "jsonrpc": "2.0",
	    "method": "host.get",
	    "params": {
	        "output": ["host"]
	    },
	    "auth": "77cec95b062cd2ab54783ef45035959c",
	    "id": 1
	}' http://192.168.56.11/zabbix/api_jsonrpc.php | python -m json.tool


效果：

	[root@linux-node2 ~]# curl -s -X POST -H 'Content-Type:application/json' -d ' 
	> {
	>     "jsonrpc": "2.0",
	>     "method": "host.get",
	>     "params": {
	>         "output": ["host"]
	>     },
	>     "auth": "77cec95b062cd2ab54783ef45035959c",
	>     "id": 1
	> }' http://192.168.56.11/zabbix/api_jsonrpc.php | python -m json.tool
	{
	    "id": 1,
	    "jsonrpc": "2.0",
	    "result": [
	        {
	            "host": "Zabbix server",
	            "hostid": "10084"
	        },
	        {
	            "host": "linux-node1.oldboyedu.com",
	            "hostid": "10105"
	        },
	        {
	            "host": "linux-node2.oldboyedu.com",
	            "hostid": "10114"
	        }
	    ]
	}


######### template

*显示所有的模板*


	curl -s -X POST -H 'Content-Type:application/json' -d '	
	{
	    "jsonrpc": "2.0",
	    "method": "template.get",
	    "params": {
	        "output": "extend",
	        "filter": {
	            "host": [
	                "Template OS Linux",
	                "Template OS Windows"
	            ]
	        }
	    },
	    "auth": "77cec95b062cd2ab54783ef45035959c",
	    "id": 1
	}' http://192.168.56.11/zabbix/api_jsonrpc.php | python -m json.tool
	

一个python的脚本（只是一个认证的）

yum install python-pip -y
pip install requests
[root@linux-node2 ~]# python zabbix_auth.py 
9e1768f8751a54fe2319f6754c83a017

###### 使用API来自动加

	curl -s -X POST -H 'Content-Type:application/json' -d '
	{
	    "jsonrpc": "2.0",
	    "method": "host.create",
	    "params": {
	        "host": "Linux server",
	        "interfaces": [
	            {
	                "type": 1,
	                "main": 1,
	                "useip": 1,
	                "ip": "192.168.56.12",
	                "dns": "",
	                "port": "10050"
	            }
	        ],
	        "groups": [
	            {
	                "groupid": "8"
	            }
	        ],
	        "templates": [
	            {
	                "templateid": "10001"
	            }
	        ]
	    },
	    "auth": "9e1768f8751a54fe2319f6754c83a017",
	    "id": 1
	}' http://192.168.56.11/zabbix/api_jsonrpc.php | python -m json.tool


[saltstack](http://www.aclstack.com/category/%E8%BF%90%E7%BB%B4%E5%B7%A5%E5%85%B7)
## 画图时间

未来自动化的蓝图

### 作业

1. 复习
2. 预习


怎么学各种监控方式（官方文档）

www.zabbix.com/documentation.php

状态  主机  监控项

折腾：

[马亮](http://www.52devops.com/chuck/630.html)
[谢迪](http://www.jixuege.com)
[良辰](http://bjstack.combjstack.com)