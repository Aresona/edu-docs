# Nginx

nginx: epoll模型、本身是静态www软件，不能解析动态的PHP等网页。可以对IP限速，限制连接数等。安装时需要pcre（perl compatible regular expressions）兼容正则表达式，rewirte模块也会用到；一般会用到的两个模块：--with-http_ssl_module、 --with-http_stub_status_module;通过nginx -V来查看编译参数；nginx主要模块：ngx_core_module、

## Introduction

### Controlling nginx

nginx支持signals controlled(针对master进程PID，当然也支持对单个进程).如：TERM,INT /QUIT/HUPUSR1/USR2/WINCH；HUP是通过新的配置文件启动一个新进程，另外优雅关掉老进程。

### A Debgging log

debug tools :可以针对选定的IP。

### Connection processing methods

nginx支持的几种连接处理试试：select/poll/kqeue/epool/\/dev/poll/eventport ,一般会自动选择最高效的处理方式，也可以通过use命令来指定具体的处理方式。

kqueue — efficient method used on FreeBSD 4.1+, OpenBSD 2.9+, NetBSD 2.0, and macOS.
epoll — efficient method used on Linux 2.6+.
其他的方式都是针对其他操作系统的。


### How Nginx processes a request

nginx处理请求过程：当一个请求来的时候，nginx会根据一些属性判断应该由哪一个server来处理，如果没有识别的话，就由默认的来处理，可以通过在listen里面的default_server来指定。当确定server后，会通过location里面的特征匹配不同的语法，并指定相应属性(包括怎么处理)。不分顺序；当一个请求来了以后会先匹配prefix，然后再匹配正则表达式，如果一个请求被重定向成其他形式后会再过滤一遍location,然后再做处理。

防盗链：在0.8.48以后，这个参数已经是默认的了。
<pre>
server {
    listen      80;
    server_name "";
    return      444;
}
</pre>

### Server names

Server Names: 也要可以通过通配符或正则表达式来匹配多个。

servername可以被用来做别名，别名一般的用法在于把多个域名指向同一个地址，另外，就是给集群中的每一台RS指定一个单独的域名，这样方便区分(监控)。



### Using nginx as HTTP load balancer
nginx支持的三种算法：RR/最小化连接/IP-HASH，默认RR；

nginx支持的反向代理包括下面这几种的负载均衡：HTTP/HTTPS/FASTCGI/UWSGI/SCGI/Memcached.。其他几种的语句：proxy_pass http/proxy_pass https/fastcti_pass/uwsgi_pass/scgi_pass/memcached_pass;

健康检查：max_fails如果设置为0就关闭健康检查，当过了fail_timeout后，会通过实时的请求优雅地探测失败的server,如果成功了，就当作一个live node。

### Architecture

架构： nginx支持的模块： core modules, event modules, phase handlers, protocols, variable handlers, filters, upstreams and load balancers.为了支持各自请求，nginx使用事件通知机制和许多操作系统的模型(epoll)，目标是为操作系统提供尽可能多的提示，以便及时雨反馈。

nginx处理请求的方式： 单线程进程，可以处理每秒数千个并发连接和请求
apache是通过独立的进程或线程处理连接。并且阻塞网络和IO操作。这时，每新启动一个进程或线程就需要准备一个新的runtime enviroment,这时就会造成CPU/内存等的浪费。

### [Apache的三种处理模块](https://www.digitalocean.com/community/tutorials/apache-vs-nginx-practical-considerations)

apache: select I/O模型   提供了多种多处理模块(MPMs)，这些模块决定了如何处理客户端请求。:mpm_prefork、mpm_worker、mpm_event。

* mpm_prefork: 这种模式下apache会生成多个单线程进程来处理请求，当请求数少于进程数时，处理起来会特别快。每个进程都会消耗很多内存，所以难以扩展。
* mpm_worker： 这种模式下也同样会生成许多进程，但不同的是，每个里程可以管理多个线程，这样不变相地实现每个进程同一时间可以处理多个请求，而不必等下一下进程空闲。
* mpm_event: 这种模式跟worker差不多，只不过经优化后用来处理长连接(keep-alive)。在worker模式下，如果一个请求是keep-alive,那么这个请求就会一直占着一个线程；而event下，会为keep-ailve请求分配专门的处理线程。如果请求active了就传递给其他的线程。


## 优化

`sendfiel		on;`

sendfile配置可以提高nginx表态资源托管效率。sendfile是一个系统调用，直接在内核空间完成文件发送，不需要先read再write，没有上下文切换开销。

`server_tokens off;`

控制 `http response header` 内的web服务版本信息的显示，以及错误信息中web服务版本信息的显示。

`worker_processes 1;

调整Nginx的worker进程数，最好和网站的用户相关联，如果不清楚用户数量，建议worker数一般可以是CPU的核数，还与存储和系统负载有关，具体看业务需要，官方建议。

`worker_cpu_affinity`

默认情况下，Nginx的多个进程有可能运行在某一个CPU或CPU的某一核上，导致Nginx进程使用硬件的资源不均，这个优化将尽可能地将不同的Nginx进程分配给不同的CPU处理，达到充分有效利用硬件的多CPU多侅资源的目的。它的作用是绑定不同的worker进程数到一组CPU上。通过设置bitmask控制进程允许使用的CPU，默认worker进程不会绑定到任何CPU上。并没有太大的效果。





`keepalive_timeout 	60`

指定服务端为每个TCP连接最多保持的时间。

`gzip 	on;`

配置对各个文件类型的压缩。

<pre>
events{
	worker_connections	1024;
}
</pre>

events表示事件，里面的内容表示一个worker processors可以处理多少并发，所以nginx的最大并发数计算为：workers*worker_connections(不准确)；另外一般worker_processes的数值跟CPU的核数相等。

> Sets the maximum number of simultaneous（并发） connections that can be opened by a worker process.
> 
It should be kept in mind（谨记） that this number includes all connections (e.g. connections with proxied servers（与被代理服务之间的连接数）, among others（与其他角色之间的）), not only connections with clients（不仅仅是与客户端之间的连接数）. Another consideration is that the actual（实际的） number of simultaneous connections cannot exceed（超过） the current limit（当前限制） on the maximum number of open files（最大文件打开数）, which can be changed by worker_rlimit_nofile （可以在worker_rlimit_nofile中改变的参数）.


### 日志

#### buffer

对于访问日志如果并发很大的话，为了节省磁盘I/O，我们可以加参数buffer来调整，这个适用于90%的情况。

<pre>
access_log logs/access.log main gzip buffer=32K flush=5s;
</pre>

另外，大公司可能会直接从内存里面读取发送到hadoop做一个不落地的日志分析。

#### 轮询切割

通过脚本移走，然后重定向空到该文件。



### 跳转

nginx的301和302跳转,nginx与apache规则区别不大，本代码实现lanyingblog.com跳转到www.lanyingblog.com，以避免搜索引擎分散权重。

<pre>
if ($host != 'www.lanyingblog.com') {
    rewrite ^/(.*)$ http://www.lanyingblog.com/$1 permanent;
}
</pre>

添加在conf配置文件内即可，一般我与伪静态的配置放在一起。代码中判断，非 `www.lanyingblog.com` 的，就自动跳转到`www.lanyingblog.com`，`permanent`代表301永久跳转，改为`redirect`则为302临时跳转。

### modules

`ngx_http_stub_status_module`

<pre>
location / {
     stub_status on;
     access_log off;
}
</pre>

`ngx_core_module`

<pre>
error_log	file 	level;
</pre>

> 可以放置在: main,http,server,location标签段中。

