要么用，要么不用（多个人来写）  一定要test, 还有就是版本控制

<pre>
git clone https://github.com/unixhot/saltbook-code.git
</pre>

session保持 

session复制，会造成一个效率问题，

session共享


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