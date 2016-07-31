### 小技巧

对于软件安装来说，我们经常会用到的就是软件升级，所以在SLS文件里面我们最好也使用JINJA变量把软件的名称单独写出来，如下面的keepavlied.install.sls文件

<pre>
[root@linux-node1 keepalived]# cat install.sls 
{% set keepalived_dir = 'keepalived-1.2.17' %}

keepalived-install:
  file.managed:
    - name: /usr/local/src/{{ keepalived_dir }}.tar.gz
    - source: salt://modules/keepalived/files/{{ keepalived_dir }}.tar.gz
    - mode: 755
    - user: root
    - group: root
  cmd.run:
    - name: cd /usr/local/src && tar zxf {{ keepalived_dir }} && cd {{ keepalived_dir }} && ./configure --prefix=/usr/local/keepalived --disable-fwmark && make && make install
    - unless: test -d /usr/local/keepalived
    - require:
      - file: keepalived-install

/etc/sysconfig/keepalived:
  file.managed:
    - source: salt://modules/keepalived/files/keepalived.sysconfig
    - mode: 644
    - user: root
    - group: root

/etc/init.d/keepalived:
  file.managed:
    - source: salt://modules/keepalived/files/keepalived.init
    - mode: 755
    - user: root
    - group: root

keepalived-init:
  cmd.run:
    - name: chkconfig --add keepalived
    - unless: chkconfig --list | grep keepalived
    - require:
      - file: /etc/init.d/keepalived

/etc/keepalived:
  file.directory:
    - user: root
    - group: root
</pre>

### 使用JINJA判断来生成keepalived主从配置文件
<pre>
[root@linux-node1 cluster]# cat haproxy-outside-keepalived.sls 
include:
  - modules.keepalived.install

keepalived-server:
  file.managed:
    - name: /etc/keepalived/keepalived.conf
    - source: salt://cluster/files/haproxy-outside-keepalived.conf
    - mode: 644
    - user: root
    - group: root
    - template: jinja
    {% if grains['fqdn'] == 'linux-node1.oldboyedu.com' %}
    - ROUTEID: haproxy_ha
    - STATEID: MASTER
    - PRIORITYID: 150
    {% elif grains['fqdn'] == 'linux-node2.oldboyedu.com' %}
    - ROUTEID: haproxy_ha
    - STATEID: BACKUP
    - PRIORITYID: 100
    {% endif %}
  service.running:
    - name: keepalived
    - enable: True
    - watch:
      - file: keepalived-server

[root@linux-node1 files]# cat haproxy-outside-keepalived.conf 
! Configuration File for keepalived
global_defs {
   notification_email {
     saltstack@example.com
   }
   notification_email_from keepalived@example.com
   smtp_server 127.0.0.1
   smtp_connect_timeout 30
   router_id {{ROUTEID}}
}

vrrp_instance haproxy_ha {
state {{STATEID}}
interface eth0
    virtual_router_id 36
priority {{PRIORITYID}}
    advert_int 1
authentication {
auth_type PASS
        auth_pass 1111
    }
    virtual_ipaddress {
       192.168.56.21
    }
}
</pre>

### haproxy会话保持

<pre>balance source</pre>

1. source表示haproxy会维护一个哈希表，请求过来的时候会记录源IP地址和分配的后端的真实机，下次请求过来后还会访问到同一台真实机。
2. 会话（session）是在服务器端产生的，为了标识唯一用户的，因为http是无状态的（前一次请求跟后一次请求没有任何关系）
3. 每一个session都有一个唯一的sessionID,它存放在客户端的cookie里面，因为浏览器在请求一个站点的时候默认会把这个站点的所有cookie发给服务端，这时服务端就可以识别客户端了。

### 解决会话的三种方法

* 会话保持
<pre>
缺点：
一个节点挂掉后客户端还是需要重新登录
负载不均衡
</pre>
* 会话复制

在所有节点复制一份，它的缺点就是效率问题，比如延时的问题

* 会话共享

全部写在一起。

### PHP的会话共享

session默认放在/tmp下，可以把它放在memcache里面,memcache是一个高性能的（分布式）缓存系统，也去持放在redis中，但是对于这种纯get/set来说，memcache的性能要高于redis,而且管理起来也比较容易，就算挂了，损失也不是很大，一般也不容易挂。

<pre>
session.save_handler = memcached 
session.save_path = "localhost:11211" 
</pre>

> 前提，php要安装memcahced的扩展模块

### Nginx与Apache调用php

#### Apache调用PHP的三种方式

* CGI方式
<pre>Action application/x-httpd-php "/php/php-cgi.exe"</pre>
* APACHE Module方式
<pre>LoadModule php5_module "c:/php/php5apache2.dll"
AddType application/x-httpd-php .php</pre>
* FastCGI方式

1. 在CGI模式下，如果客户机请求一个php文件，Web服务器就调用php.exe去解释这个文件，然后再把解释的结果以网页的形式返回给客户机；
2. 在模块化(DLL)中，PHP是与Web服务器一起启动并运行的。所以从某种角度上来说，以apache模块方式安装的PHP4有着比CGI模式更好的安全性以及更好的执行效率和速度。
3. fpm进程既可以监听一个本地的端口，也可以监听一个socket

### 端口号与socket的区别

socket就是一个本地操作系统文件，可以直接访问这个文件；对于IP和端口来说可以放到其他的机器上，如果监听127.0.0.1：端口的话效果跟socket是差不多的，不会走网卡的。但是用socket的话，在高并发时不太稳定；监听的9000端口不是http协议的端口，它是通过fastcgi_pass转过去的，不是通过proxy_pass转过去的。

### 标准

在线上服务器，每一个普通用户的UID全网统一。如WWW用户UID改为1000

### memcache启动

<pre>
memcached-service:
  cmd.run:
    - name: /usr/local/memcached/bin/memcached -d -m 128 -p 11211 -c 8096 -u www
    - unless: netstat -ntlp|grep 11211
    - require:
      - cmd: memcached-source-install
      - user: www-user-group 
</pre>

> nginx等reload其实也是重启，但它是一个进程一个进程地进行重启，所以对我们来说没影响

### Nginx与Apache的区别

最大的区别在于IO模型，一个是select模型，另外一个是epoll模型；

还有就是层次感，如负载均衡，LVS负载均衡是IP负载均衡，NGINX负载均衡叫反向代理负载均衡。



### saltstack目录规划说明

一般在modules里面存放的一般就是不会变动的东西，而一般配置文件和启动等也会因为业务的不同不一样，所以也要放在业务层面，modules里面只放安装相关的。

### 302调度中心

302是临时跳转，如在CDN，通过智能DNS分发一个请求到一个节点时，如果不准的话，这时就会很慢，这时就可以通过302来再调度到本来的节点，因为你请求到了后就会知道你的真实源IP。

### PHP模块

PHP要支持某些功能就需要加模块，这个和apache是一样的，nginx新版也支持动态模块添加。（这里的PHP可以直接在生产跑的）

* pdo_mysql.so

这个模块是用来连接MySQL的，也需要通过phpize来编译安装。安装成功后会放在 `/usr/local/php-fastcgi/lib/php/extensions/*/pdo_myssql.so` 下面

* 两个配置文件，一个启动文件

`/usr/local/php-fastcgi/etc/php.ini`

`/usr/local/php-fastcgi/etc/php-fpm.conf`

`/etc/init.d/php-fpm`

> 这里有一个思想就是不同的业务PHP配置文件是不一样的，所以把相同的东西放在这里，把不同业务用到的配置通过 `append` 模块来追加到最后。另外还有memcache和redis的模块，因为不是每个业务都需要，所以这两个模块单独存放，不放在PHP的安装SLS文件里面。

* redis.so
* memcache.so

> 除了pdo_msyql.so外，另外的两个模块因为不同业务的使用情况不一样，所以另外分开。

### Nginx相关

> 这里的思想就是nginx配置文件下面包含一个目录来放置各个业务的配置文件，而在nginx的modules里面放置的配置文件是全网通用的。反正最佳的就是把不变的放在modules里面，其他的放在业务模块里面。

另外一点就是上面包含的这个目录当做是上线的目录，对于下线的业务，不删除，在同一级目录下面再专门创建一个下线的目录，把这些下线的配置文件放在里面。并且还可以看到这台机器曾经运行过哪些业务。






 

要么用，要么不用（多个人来写）  一定要test, 还有就是版本控制

<pre>
git clone https://github.com/unixhot/saltbook-code.git
</pre>


PHP特别容易做session共享

要定位好，不做运维开发，运维中开发最牛逼的，开发中运维最牛逼

站的位置不同，以后的发展道路不同，可以站在产品的角度，既然做了就站在产品的角度来做

302调度中心

PHP模块，PHP要支持某些功能就需要加模块，这个和apache是一样，nginx新版也支持动态模块添加

做前面的架构

nginx配置文件最佳实践

在nginx里面include了一个目录，所以nginx.conf全网都是统一的。

<pre>salt '*' saltutil.running
salt '*' saltutil.kill_job jid
</pre>

有些浏览器不支持cookie的时候。
把sessionid附带到URL上


生产saltstack只用于基础服务，saltstack只是会检查一下，其实是用快照来做的，docker镜像更快，



<pre>cd /var/cache/salt/master/jobs</pre>

<pre>keep_jobs: 24</pre>


### 开启job cache使用
<pre>yum install MySQL-python
vim /etc/salt/master
master_job_cache: mysql
mysql.host: '192.168.56.11'
mysql.user: 'salt'
mysql.pass: 'salt@pw'
mysql.db: 'salt'
mysql.port: 3306
systemctl restart salt-master
</pre>

### job管理
#### saltutil

* clear_cache (移除minion上的全部缓存)

<pre>salt '*' saltutil.clear_cache</pre>

> 删除缓存最安全的办法就是先停掉minion,然后删掉缓存文件再重启minion

* saltutil.refresh_pillar

<pre>salt '*' saltutil.refresh_pillar</pre>

* saltutil.running  

[running](https://www.unixhot.com/docs/saltstack/ref/modules/all/salt.modules.saltutil.html#module-salt.modules.saltutil)  (Return the data on all running salt processes on the minion)

* saltutil.kill_job

<pre>salt '*' saltutil.kill_job jid</pre>
一般就是ctrl+c后它还在执行，这时就可以kill掉。如果直接杀进程的话需要在每个minion端来执行。

#### RUNNERS
Salt runners跟 Salt 的执行模块很像，但它是在master端执行的，而不是在minion端执行，它也支持很多的模块

##### manage
主要查看哪些主机启动，哪些主机宕机
<pre>salt-run manage.status
salt-run manage.down
salt-run manage.up
salt-run manage.versions
</pre>
##### jobs
用于管理jobs
<pre>
salt-run jobs.actived
salt-run jobs.list_jobs
slat-run jobs.lookup_jid jid
</pre>

<pre>salt-run jobs.print_job jid</pre>
通过JID打印出一个指定JOB的所有细节包括返回的数据
> 生产中会用到的，一个是cache，另外一个就是job管理

# salt架构

上面讲的都是基于Master-Minion来讲的，也是最经典的一个

## Masterless架构(无Master的架构)

使用salt-call命令

### 配置
<pre
/etc/salt/minion
file_client: local
file_roots:
  base:
    - /srv/salt/
pillar_roots
</pre>

> saltstack安装salt-master,并使用上编写的案例

步骤：

0. 关闭salt-minion进程 
1. 修改minion配置文件
2. 编写SLS
3. salt-call --local state.highstate

## Multi-Master(多Master架构)

为了解决单点故障

最重要的是共享key和file_roots/pillar_roots

在minion配置文件里面修改
<pre>
master:
  - 192.168.56.11
  - 192.168.56.13
</pre>

> 一个master，但所有的配置都是放在git上的。

> SLS使用git或者svn管理

## Salt Syndic

相当于一个代理

1. Salt Syndic必须运行在一个master上
2. Syndic要连接另外一个Master,比它更高级


### 实践

在linux-node2上装一个salt-master

yum install salt-syndic


<pre>
Resolving Dependencies
--> Running transaction check
---> Package salt-master.noarch 0:2015.5.10-2.el7 will be installed
--> Processing Dependency: salt = 2015.5.10-2.el7 for package: salt-master-2015.5.10-2.el7.noarch
--> Finished Dependency Resolution
Error: Package: salt-master-2015.5.10-2.el7.noarch (epel)
           Requires: salt = 2015.5.10-2.el7
           Installed: salt-2016.3.1-1.el7.noarch (@salt-latest)
               salt = 2016.3.1-1.el7
           Available: salt-2015.5.10-2.el7.noarch (epel)
               salt = 2015.5.10-2.el7
 You could try using --skip-broken to work around the problem
 You could try running: rpm -Va --nofiles --nodigest
</pre>

linux-node1
vim /etc/salt/master

master只接收来自更高级的master的执行命令，便是执行完后不会直接给master回复 



可以用于多机房，还可以建立多级的层级关系，还有一个就是它们之间的传输是经过加密的，所以不需要考虑安全的问题。

重点：  Syndic的file_roots和pillar_roots必须与高级Master一致

这里使用git或者svn来管理。

缺点： 高级的Master并不知道自己到底有多少minion。


# salt-ssh

如果不想装minion的时候就可以用这个，在0.17版本就支持SSH了，完全不需要安装Agent,但是SSH没有minion方式快，因为SSH是串行的，所以会低于minion的速度。

<pre>
master:
yum install salt-ssh -y
</pre>

## 配置SALT SSH ROSTER
<pre>
vim /etc/salt/roster
linux-node1.oldboyedu.com:
  host: 192.168.56.11
  user: root
  port: 22

linux-node2.oldboyedu.com:
  host: 192.168.56.12
  user: root
  port: 22
</pre>
<pre>
salt-ssh '*' test.ping -i(在.ssh里面写一个config文件加上配置就不会去询问了StricHostKeyChecking no)
/etc/salt/pki/master/ssh
</pre>
## 参数
<pre>
salt-ssh '*' -r 'ifconfig'
salt-ssh '*' state.highstate
</pre>
用master-minion存在机器没响应，用salt-ssh更保险，命令只能执行一次，机器还很多，必须执行，就可以用这条命令。是一个辅助


# salt-api

[文档](https://www.unixhot.com/docs/saltstack/ref/netapi/all/salt.netapi.rest_cherrypy.html)

要使用的步骤：

1. https证书
2. 配置文件
3. 验证。使用PAM验证
4. 启动salt-api

<pre>
useradd -M -s /sbin/nologin saltapi
passwd saltapi
cd /etc/pki/tls/certs
make testcert
cd /etc/pki/tls/private
openssl rsa -in localhost.key -out salt_nopass.key 
yum install python-pip
pip install --upgrade pip
pip install CherryPy==3.2.6(yum install python-cherrypy)
vim /etc/salt/master
default_include: master.d/*.conf
cd /etc/salt/master.d
vim api.conf
rest_cherry:
  host: 192.168.56.11
  port: 80
  ssl_cert: /etc/pki/tls/certs/localhost.crt
  ssl_key: /etc/pki/tls/private/salt_nopass.key
[root@linux-node1 master.d]# cat eauth.conf 
external_auth:
  pam:
    saltapi:
      - .*
      - '@wheel'
      - '@runner'
# 可插入式验证模块
yum install salt-api -y
systemctl restart salt-master
systemctl start salt-api
</pre>
测试
<pre>
curl -k https://192.168.56.11:8000/login \
-H 'Accept: application/x-yaml' \
-d username='saltapi' \
-d password='saltapi' \
-d eauth='pam'
</pre>
<pre>
[root@linux-node1 ~]# curl -k https://192.168.56.11:8000/minions/linux-node1.oldboyedu.com \
-H 'Accept: application/x-yaml' \
-H 'X-Auth-Token: 785db9bc5e79dee828bfb1649bc49c59900e0ebf' \
</pre>

检测机器的状态
<pre>
curl -k https://192.168.56.11:8000/ \
-H 'Accept: application/x-yaml' \
-H 'X-Auth-Token: 785db9bc5e79dee828bfb1649bc49c59900e0ebf' \
-d client='runner' \
-d fun='manage.status'
</pre>
使用api执行远程模块
<pre>
curl -k https://192.168.56.11:8000/ \
-H 'Accept: application/x-yaml' \
-H 'X-Auth-Token: 785db9bc5e79dee828bfb1649bc49c59900e0ebf' \
-d client='local' \
-d tgt='*' \
-d fun='test.ping'
</pre>
### 写好的API
[小的oms平台](https://github.com/binbin91/oms)

[dashboard](https://github.com/yueyongyue/saltshaker)
<pre>
git clone https://github.com/binbin91/oms

</pre>