Rsyslog、TCP日志

# Rsyslog
实现通过ES存储Rsyslog,这里把56.11的日志远程发到56.12上，然后展示到kibana上

syslog是通过端口514收集日志，如果是rsyslog协议的时候，也有单独的插件

### 配置ES关于syslog
<pre>
[root@linux-node2 conf.d]# cat syslog.conf 
input {
    syslog {
	type => "system-syslog"
	port => 514
    }

}
output {
    stdout {
	codec => rubydebug 
    }
}
</pre>

56.11上rsyslog日志配置并重启
<pre>
*.* @@192.168.56.12:514
</pre>
56.12上配置发送到esticsearch

<pre>
[root@linux-node2 conf.d]# cat syslog.conf 
input {
    syslog {
	type => "system-syslog"
	port => 514
    }

}
output {
    elasticsearch {
	hosts => ["192.168.56.12:9200"]
	index => "system-syslog-%{+YYYY.MM}"
    }
}
</pre>
通过logger命令来生成日志

logger hehe
查看ES及KIBANA界面并配置
192.168.56.12:9200/_plugin/head

192.168.56.11:5601

settings-  [system-syslog-]YYYY.MM


## TCP插件

这个插件主要用来实现一些数据想补进去，就会通过TCP的方式补进去，对ES来说日志是没顺序的。

<pre>
[root@linux-node2 conf.d]# cat tcp.conf 
input {
    tcp {
	type => "tcp"
	port => "6666"
	mode => "server"
    }
}
output {
    stdout {
	condec => rubydebug

    }
}
/opt/logstash/bin/logstash -f /etc/logstash/conf.d/tcp.conf</pre>
这时就会在本地的6666端口开始监听请求，我们可以通过nc命令传递相关消息
<pre>
echo "hehe" |nc 192.168.56.12 6666
nc 192.168.56.12 6666 < /etc/resolv.conf
echo "hehe1" > /dev/tcp/192.168.56.12/6666
</pre>

abs书

## filter插件 grok
用来拆分字段的插件　，如把apache日志拆成json的格式
<pre>
yum install httpd -y
修改端口为81
</pre>
它利用正则表达式进行匹配并拆分，它提供了一些预定义的正则表达式，它们放在`/opt/logstash/vendor/bundle/jruby/1.9/gems/logstash-patterns-core-2.0.5/patterns`下
<pre>
[root@linux-node1 conf.d]# cat grok.conf 
input {
   stdin {}
}

filter {
   grok {
    match => { "message" => "%{IP:client} %{WORD:method} %{URIPATHPARAM:request} %{NUMBER:bytes} %{NUMBER:duration}" }
  }

}

output {
    stdout {
        codec => rubydebug
    }
}

</pre>
监听并发送日志查看效果
<pre>
[root@linux-node1 conf.d]# /opt/logstash/bin/logstash -f /etc/logstash/conf.d/grok.conf 
Settings: Default pipeline workers: 4
Pipeline main started
55.3.244.1 GET /index.html 15824 0.043
{
       "message" => "55.3.244.1 GET /index.html 15824 0.043",
      "@version" => "1",
    "@timestamp" => "2016-08-27T03:16:27.809Z",
          "host" => "linux-node1.oldboyedu.com",
        "client" => "55.3.244.1",
        "method" => "GET",
       "request" => "/index.html",
         "bytes" => "15824",
      "duration" => "0.043"
</pre>

1. grok是非常影响性能的
2. 不灵活，除非很懂ruby

建议方式：logstach收集到redis，然后通过python脚本把它从redis读出来再写到ES里面。这样python脚本就可以使用多进程了。

api.php?user=aaa&a=b&c=d&id=kjkjkjk&pw=xxx
api.php?user=aaa&c=d&a=b&id=kjkjkjk&pw=xxx

建议：前端只收，后端再做处理。

Apache状态码

dashboard -- 文件  add visiualation 


确保两台机器都有ELK,然后在12上安装redis，

# 松耦合架构

松耦合方法：
1. 通过中间来完成（前后端不一样，前后端不依赖）


logstash支持的消息队列：看看output插件有几个就知道支持几个了。如rabbitmq、redis、kafka等。
## Redis
Redis消息队列非常简单，一个消息没收到就是没了，Redis还有一个数据存储的格式就是list。

**56.11**
redis默认的DB是0，数据类型我们用list,key；在56.11上启动一个logstash,并把数据写到56.12上的redis上面
<pre>
[root@linux-node1 conf.d]# cat redis.conf 
input {
    stdin {}
}
output {
    redis {
	host => "192.168.56.12"
	port => "6379"
	db => "6"
	data_type => "list"
	key => "demo"
    }
}
</pre>
<pre>
/opt/logstash/bin/logstash -f redis.conf 
</pre>
<pre>
daemonize yes
bind 192.168.56.12
systemctl start redis
redis-cli -h 192.168.56.12
INFO
set name kkk
get name
select 6
keys *
type demo
llen demo
lindex demo -1
</pre>
### apache
<pre>
[root@linux-node1 conf.d]# cat apache.conf 
input {
    file {
        path => "/var/log/httpd/access_log"
        start_position => "beginning"
    }

}
output {
    redis {
	host => "192.168.56.12"
	port => "6379"
	db => "6"
	data_type => "list"
	key => "apache-accesslog"
    }
}
[root@linux-node1 conf.d]# /opt/logstash/bin/logstash -f apache.conf
</pre>

**56.12**
在56.12上启动一个logstach，并从redis 6上面读。
[官网](https://www.elastic.co/guide/en/logstash/current/plugins-inputs-redis.html)
<pre>
[root@linux-node2 conf.d]# cat indexer.conf 
input {
    redis {
	host => "192.168.56.12"
	port => "6379"
	db => "6"
	data_type => "list"
	key => "apache-accesslog"
    }
}
filter {
    grok {
	    match => { "message" => "%{IP:client} %{WORD:method} %{URIPATHPARAM:request} %{NUMBER:bytes} %{NUMBER:duration}" }
    }
}
output {
    stdout {
   	codec => rubydebug 
    }
}
</pre>

写在es里面
<pre>
[root@linux-node2 conf.d]# cat indexer.conf 
input {
    redis {
	host => "192.168.56.12"
	port => "6379"
	db => "6"
	data_type => "list"
	key => "apache-accesslog"
    }
}
filter {
    grok {
	    match => { "message" => "%{IP:client} %{WORD:method} %{URIPATHPARAM:request} %{NUMBER:bytes} %{NUMBER:duration}" }
    }
}
output {
    elasticsearch {
	hosts => ["192.168.56.11:9200"]
	index => "apache-accesslog-%{+YYYY.MM.dd}"
    }
}
/opt/logstash/bin/logstash -f /etc/logstash/conf.d/indexer.conf 
</pre>
上面就是使用消息队列对ELK进行解耦

## Kafka快速入门
作为作业 

# 生产项目案例（使用）
**需求分析**：

1. 访问日志：Apache、Nginx、Tomcat、ES错误日志  （file--filter）
2. 错误日志：error.log、java日志（需要使用多行插件进行处理、文件的错误日志）(直接收或者使用多行插件进行处理)
3. 系统日志: /var/log/* syslog（直接通过syslog收）
4. 运行日志：程序写的，开发喜欢写一些重要的日志（肯定是file,可以写成json的）
5. 网络日志：防火墙、交换机、路由器的日志（syslog）

##
1. 标准化：日志放哪里(/data/logs)，格式是什么(JSON)，命名规则(access_log/error_log/runtime_log)，日志怎么切割（按天，按小时）（access和errorlog通过crontab进行切分，runtime_log是直接写的，到下个小时就生成一个新文件，所有的原始文本rsync到NAS后，删除三天前的）/
2. 工具化：如何使用logstash进行收集方案（插件：file,需要写各种IF判断）


<pre>
#!/bin/bash
DATE=`date -d "30 days ago" +%Y.%m.%d`
LOG_NAME="apache-accesslog"
#echo ${LOG_NAME}-${DATE}
curl -XDELETE 'http://192.168.56.11:9200/${LOG_NAME}-${DATE}'
#定期删除elasticsearch一个月之前的index
</pre>
**56.11**
<pre>
[root@linux-node1 conf.d]# cat indexer.conf 
input {
   syslog {
     type => "system-syslog"
     port => 514
   }
   redis {
        type => "apache-accesslog"
        host => "192.168.56.12"
        port => "6379"
        db => "6"
        data_type => "list"
        key => "apache-accesslog"
    }
    redis {
        type => "es-log"
        host => "192.168.56.12"
        port => "6379"
        db => "6"
        data_type => "list"
        key => "es-log"
    }

}

filter {
    if [type] == "apache-accesslog" {
    	grok {
        	match => { "message" => "%{COMBINEDAPACHELOG}" }
    	}
    }

}

output {
    if [type] == "apache-accesslog" {
    	elasticsearch {
       		hosts => ["192.168.56.11:9200"]
        	index => "apache-accesslog-%{+YYYY.MM.dd}"
    	}
    }
    if [type] == "es-log" {
        elasticsearch {
                hosts => ["192.168.56.11:9200"]
                index => "es-log-%{+YYYY.MM}"
        }
    }
    if [type] == "system-syslog" {
        elasticsearch {
                hosts => ["192.168.56.11:9200"]
                index => "system-syslog-%{+YYYY.MM}"
        }
    }
}
</pre>
**56.12**
<pre>
[root@linux-node2 conf.d]# cat shipper.conf 
input {
    file {
        path => "/var/log/httpd/access_log"
        start_position => "beginning"
        type => "apache-accesslog"
    }
    file {
        path => "/var/log/elasticsearch/myes.log"
        type => "es-log"
        start_position => "beginning"
        codec => multiline{
          pattern => "^\["
          negate => true
          what => "previous"
        }
    }


}

output {
    if [type] == "apache-accesslog" {
        redis {
                host => "192.168.56.12"
                port => "6379"
                db => "6"
                data_type => "list"
                key => "apache-accesslog"
        }
    }
    if [type] == "es-log" {
    	redis {
        	host => "192.168.56.12"
        	port => "6379"
        	db => "6"
        	data_type => "list"
        	key => "es-log"
    	}
    }
}
</pre>
修改  `/etc/init.d/logstash` 否则会有权限问题，不能读取httpd日志
<pre>
LS_USER=root
LS_GROUP=root
</pre>
如果使用redis list作为ELK的消息队列，请对所有list key的长度进行监控，llen key_name，根据实际情况，例如超过10万就报警。


# 作业
把消息队列换成kafka[推荐文章](https://www.unixhot.com/article/61)
[infoq](http://www.infoq.com)

生产实践

深度实践：数据写入haddop 使用web-hdfs写入。

ELK和haddop的区别

ELK偏实时，hadoop偏离线，因为它涉及的量很大，不推荐用ELK统计PV/UV等。

# 回顾

运维知识体系
cobbler自动化安装 、yum仓库


python ide