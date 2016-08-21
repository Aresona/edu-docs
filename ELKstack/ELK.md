查询tracert
<pre>mtr -n www.uninx.com</pre>

-n  就是不做域名解析，可以看到实时丢包率

基于ELKStack构建日志平台

对于中小企业，运维经常会有拿日志，看日志的需求，同期对比等。所以为了让自动化领域，我们要对日志进行收集、存储、搜索、展示等功能。

这三个软件都属于elastic.co这个公司的。

Elasticsearch 是 面向文档型数据库，这意味着它存储的是整个对象或者 文档，它不但会存储它们，还会为他们建立索引，这样你就可以搜索他们了。

在 Elasticsearch 中，存储数据的行为就叫做 索引(indexing) 但是在我们索引数据前，我们需要决定将数据存储在哪里。

在 Elasticsearch 中，文档属于一种 类型(type)，各种各样的类型存在于一个 索引 中。你也可以通过类比传统的关系数据库得到一些大致的相似之处：
<pre>
关系数据库     ⇒ 数据库 ⇒ 表    ⇒ 行    ⇒ 列(Columns)
Elasticsearch  ⇒ 索引   ⇒ 类型  ⇒ 文档  ⇒ 字段(Fields)</pre>
一个 Elasticsearch 集群可以包含多个 索引（数据库），也就是说其中包含了很多 类型（表）。这些类型中包含了很多的 文档（行），然后每个文档中又包含了很多的 字段（列）。

[架构图]()

这些角色都是社区给定义的。redis的加入主要是为了解耦。还有就是缓冲的作用。

### 配置文件
**/etc/elasticsearch/elasticsearch.yml**

<pre>
cluster.name: myes		# 集群名称
node.name: linux-node1		# 节点名
path.data: /data/es-data 		# 数据存储的目录
path.logs: /var/log/elasticsearch/
bootstrap.mlockall: true	# 锁住内存，不放在swap下
network.host: 192.168.56.11
http.port: 9200
</pre>

<pre>
systemctl start elasticsearch
chown -R elasticsearch.elasticsearch /data/es-data/
</pre>
<pre>
[root@linux-node1 ~]# curl -i -XGET 'http://192.168.56.11:9200/_count?'
HTTP/1.1 200 OK
Content-Type: application/json; charset=UTF-8
Content-Length: 59

{"count":0,"_shards":{"total":0,"successful":0,"failed":0}}
</pre>

装插件
<pre>
cd /usr/share/elasticsearch/bin/
./plugin install marvel-agent
./plugin install marvel
./plugin install head
./plugin install mobz/elasticsearch-head
</pre>
浏览器访问
192.168.56.11:9200/_plugin/head/

/usr/share/elasticsearch/plugins/head



还有一个是bigdesk插件，直接在github上搜 ，然后下载

<pre>
/usr/share/elasticsearch/bin/plugin install lukas-vlcek/bigdesk

</pre>

kopf插件，它内容更全
<pre>
/usr/share/elasticsearch/bin/plugin install lmenezes/elasticsearch-kopf
</pre>

#### head插件
192.168.56.11:9200/_plugin/head/
首先写数据进去

[网址](https://github.com/mobz/elasticsearch-head)

正常情况下，主分片跟副本分片不是放在一台机器上

绿色代表运行良好。
集群健康值：
黄色代表没有主分片数据丢失，但是它不是一个健康的状态，警告

红色代表有数据丢失。

当索引多了后，head插件打开得5分钟，而且带宽也特别大

#### kopf插件 

[官网](https://github.com/lmenezes/elasticsearch-kopf)


# 集群
在56.12上安装elasticsearch,并修改配置文件，并启动服务 

默认情况下ES是使用组包的方式通信的，也就是看其他节点是不是同一个cluster name,并选举一个主节点，

health?pretty=true

## 监控
<pre>
curl -XGET 'http://192.168.56.11:9200/_cluster/health?pretty=true'
</pre>



# LOGstash
大量的工作其实是在收集；logstash没有什么agent/server,它就是自己，对它来说，没有任何角色，就是做日志的收集

## 基本概念
logstash用它收集，简单的说就是修改配置文件

* INPUT/OUTPUT

它做一个运输者的身份时，数据从哪来到哪去，它有一个FILTER的功能，在发之前做一个过滤 

## GET STARTED
<pre>
rpm -ql logstash
cd /opt/logstash/bin/logstash
/opt/logstash/bin/logstash -e 'input { stdin{} } output { stdout{} }'
</pre>

<pre>
[root@linux-node2 yum.repos.d]# /opt/logstash/bin/logstash -e 'input { stdin{} } output { stdout{} }'
Settings: Default pipeline workers: 2
Pipeline main started
hello
2016-08-20T11:53:14.043Z linux-node2.oldboyedu.com hello
world
2016-08-20T11:53:31.628Z linux-node2.oldboyedu.com world
</pre>
<pre>
[root@linux-node2 ~]# /opt/logstash/bin/logstash -e 'input { stdin{} } output { stdout{ codec => rubydebug} }'
Settings: Default pipeline workers: 2
Pipeline main started
hello     
{
       "message" => "hello",
      "@version" => "1",
    "@timestamp" => "2016-08-20T11:54:41.089Z",
          "host" => "linux-node2.oldboyedu.com"
}
wold
{
       "message" => "wold",
      "@version" => "1",
    "@timestamp" => "2016-08-20T11:54:46.197Z",
          "host" => "linux-node2.oldboyedu.com"
}
</pre>

### 把日志写在ES里面
需求：从标准输入来收，但是写在ES里面

那就需要OUTPUT的ES的插件
<pre>/opt/logstash/bin/logstash -e 'input { stdin{} } output { stdout{ elasticsearch { hosts => ["192.168.56.11:9200"] index => "logstash-%{+YYYY.MM.dd}"} } }'</pre>

<pre>
[root@linux-node2 ~]# /opt/logstash/bin/logstash -e 'input { stdin{} } output { stdout{ codec => rubydebug } elasticsearch { hosts => ["192.168.56.11:9200"] index => "logs tash-%{+YYYY.MM.dd}" } }'
Settings: Default pipeline workers: 2
Pipeline main started
hehe 
h{
       "message" => "hehe ",
      "@version" => "1",
    "@timestamp" => "2016-08-20T12:05:12.458Z",
          "host" => "linux-node2.oldboyedu.com"
}
</pre>


需求：
1. 收集系统日志

<pre>
rsyslog ==> es
file ==> es
tcp ==> es
</pre>


# RESTful API

网络应用程序，分为前端和后端两个部分。当前的发展趋势，就是前端设备层出不穷（手机、平板、桌面电脑、其他专用设备......）。

因此，必须有一种统一的机制，方便不同的前端设备与后端进行通信。这导致API构架的流行，甚至出现"API First"的设计思想。RESTful API是目前比较成熟的一套互联网应用程序的API设计理论。我以前写过一篇[理解RESTful架构](http://www.ruanyifeng.com/blog/2014/05/restful_api.html)，探讨如何理解这个概念。

* 协议

API与用户的通信协议，总是使用HTTPS协议

* 域名

应该尽量将API部署在专用域名之下，如果确定API很简单，不会有进一步扩展，可以考虑放在主域名下。
<pre>
https://example.org/aip/
</pre>

* 版本

应该将API的版本号放入URL

<pre>
https://api.example.com/v1/
</pre>
另一种做法是，将版本号放在HTTP头信息中，但不如放入URL方便和直观。


写一个配置文件

<pre>
cat /etc/logstash/conf.d/demo.conf
input{
    stdin{}
}

filter{
}
output{
    elasticsearch {
        hosts => ["192.168.56.11:9200"]
        index => "logstash-%{+YYYY.MM.dd}"
    }
    stdout{
        codec => rubydebug
    }

}
 /opt/logstash/bin/logstash -f /etc/logstash/conf.d/demo.conf
</pre>
> 写数组的话是用中括号来表示，字符串加双引号，#用来注释

1. 在logstash中，一行内容叫做一个事件，一个事件可以是一行，也可以是多行
2. input output(一个流程里面必须有这两个)
3. 事件  -->  input   -->   codec    -> filter --> codec   --> output


#### 文件收集

<pre>
[root@linux-node1 conf.d]# cat file.conf 
input{
    file{
	path => ["/var/log/messages","/var/log/lastlog"]
	type => "system-log"
	start_position => "beginning"
    }
}
filter{
}
output{
    elasticsearch {
        hosts => ["192.168.56.11:9200"]
        index => "system-log-%{+YYYY.MM}"
    }
}
/opt/logstash/bin/logstash -f /etc/logstash/conf.d/file.conf
</pre>
 

### 实现不同日志放在不同索引
<pre>
cat file.conf
input{
    file{
	path => ["/var/log/messages","/var/log/lastlog"]
	type => "system-log"
	start_position => "beginning"
    }
    file{
 	path => "/var/log/elasticsearch/myes.log"
	type => "es-log"
    }
}
filter{
}
output{
    if [type] == "system-log" {
        elasticsearch {
            hosts => ["192.168.56.11:9200"]
            index => "system-log-%{+YYYY.MM}"
        }
    }
    if [type] == "es-log" {
        elasticsearch {
            hosts => ["192.168.56.11:9200"]
            index => "es-log-%{+YYYY.MM}"
        }
    }
}
/opt/logstash/bin/logstash -f /etc/logstash/conf.d/file.conf
</pre>
> 日志文件里面不能有type == xxx的东西



# kinbana
<pre>
rpm -ql kinbana
</pre>
kinbana是专门为ES设计的可视化平台。它跟logstash没有任何关系，需要的配置只是关于ES的配置
d

/etc/init.d/kibana start
192.168.56.11:5601



### 收集Nginx的访问日志
把nginx访问日志改成json格式。

#### 如何规划一个日志收集系统？
最难的是标准化

1. 标准位置

<pre>
yum install nginx -y
systemctl start nginx
ab -n 1000 -c 1 http://192.168.56.12/
</pre>
访问日志
<pre>192.168.56.12 - - [21/Aug/2016:00:04:33 +0800] "GET / HTTP/1.0" 200 3700 "-" "ApacheBench/2.3" "-"</pre>

修改nginx日志格式为JSON
<pre>
vim /etc/nginx/nginx.conf
log_format  access_log_json  '{"user_ip":"$http_x_real_ip","lan_ip":"$remote_addr","log_time":"$time_iso8601","user_req":"$request","http_code":"$status","body_bytes_sent":"$body_bytes_sent","req_time":"$request_time","user_ua":"$http_user_agent"}';
access_log  /var/log/nginx/access_log_json.log  access_log_json;
</pre>

* 文件直接收取到redis,再用python脚本读取写成json，写入ES

如果想把URL里面的？后面的参数写成JSON的时候，用logstash就不好实现了；或者访问日志是加密的，需要跑一个python脚本把它解密。


生产kibana

1. 每个ES上面都启动一个kibana
2. kibana都连自己的ES
3. 前端Nginx负载均衡+ip_hash+验证+ACL

> hadoop 偏离线计算，ES偏实时搜索