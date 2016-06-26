# 运维自动化之SaltStack

## 简介

SaltStack是用python语言写的，提供了API、支持多种操作系统（所有类Unix系统都默认安装Python），windows只能安装Minion端程序。

[官网](https://saltstack.com/)

[中国SaltStack用户组](http://www.saltstack.cn)

### SaltStack 三大功能：

* 远程执行
* 配置管理（状态、很难回滚）
* 云管理

> 运维三板斧：监控、执行、配置管理

类似软件：Puppet(ruby)、Ansible（python）



### 四种运行方式

* Local
* Master/Minion（传统C/S架构）
* Syndic（对应于zabbix的proxy)
* Salt SSH

> 由于C/S模式需要在每台客户端机器上安装Salt-Minion,很多人会觉得麻烦,但是最佳的体验就是装一个Minion。

### 典型案例

阿里大数据部门、360的远程执行

## QUICK START

### 安装

1. 通过epel源安装
2. 通过saltstack自己的仓库安装
<pre>
yum install https://repo.saltstack.com/yum/redhat/salt-repo-latest-1.el7.noarch.rpm -y
</pre>

######  Master端
<pre>
yum install salt-master salt-minion -y
</pre>

###### Minion端
<pre>
yum install salt-minion -y
</pre>

######  windows下Minion安装
<pre>
Salt-Minion-2016.3.1-AMD64-Setup.exe /S /master=yoursaltmaster /minion-name=yourminionname
</pre>

### 配置及启动

###### 启动salt-master
<pre>
systemctl start salt-master
</pre>

###### 配置并启动minion
<pre>
sed -i 's/# master: salt/master: 192.168.56.11/' /etc/salt/minion
systemctl start salt-minion
</pre>
另外一个重要的参数就是id,每个minion都有一个单独的ID，它也放在 	`/etc/salt` 目录下，如果不改的话，默认就是主机名
<pre>
[root@linux-node2 salt]# cat minion_id 
linux-node2.example.com
</pre>

> 这个ID不建议改，如果要改的话，要先把这个文件删除了。因为master会首先读这个文件，生产中可以用主机名，id可以不配，如果不配，它就会用主机名。

### 认证
SaltStack是通过AES来加密的，所以一般不需要关注安全性问题，一般Minion启动的时候就会在/etc/salt下建立一个pki的目录，生成密钥对并把里面的公钥发给Master端。
<pre>
[root@linux-node2 salt]# tree pki
pki
├── master
└── minion
    ├── minion.pem		私钥
    └── minion.pub		公钥
[root@linux-node1 salt]# tree pki/
pki/
├── master
│   ├── master.pem		Master私钥
│   ├── master.pub		Master公钥
│   ├── minions
│   ├── minions_autosign
│   ├── minions_denied
│   ├── minions_pre
│   │   ├── linux-node1.example.com		Minion发过来的两个私钥
│   │   └── linux-node2.example.com		默认会使用Minion_ID来做私钥的名称
│   └── minions_rejected
└── minion
    ├── minion.pem		Minion私钥
    └── minion.pub		Minion公钥
[root@linux-node1 salt]# md5sum pki/master/minions_pre/linux-node2.example.com 
eed44ea7c9d65c7aeddd56dedcebd3df  pki/master/minions_pre/linux-node2.example.com
[root@linux-node2 salt]# md5sum pki/minion/minion.pub 
eed44ea7c9d65c7aeddd56dedcebd3df  pki/minion/minion.pub
</pre>

###### 列出所有keys
<pre>
[root@linux-node1 salt]# salt-key 
Accepted Keys:
Denied Keys:
Unaccepted Keys:
linux-node1.example.com
linux-node2.example.com
Rejected Keys:
</pre>
###### Master端同意所有申请管理的Minion端keys
<pre>
salt-key -a linux-node1.example.com
salt-key -a linux-node*
salt-key -A
[root@linux-node1 salt]# tree pki/
pki/
├── master
│   ├── master.pem
│   ├── master.pub
│   ├── minions
│   │   ├── linux-node1.example.com		## Master同意
│   │   └── linux-node2.example.com
│   ├── minions_autosign
│   ├── minions_denied
│   ├── minions_pre
│   └── minions_rejected
└── minion
    ├── minion_master.pub		## 这个是Master的公钥（认证后Master端会把自己的公钥发给Minion端）
    ├── minion.pem
    └── minion.pub
</pre>

> 认证的过程就是公钥交换的过程，改完ID后所有的认证就得重新来做一遍

### ID的设置

ID设置有两种方式，一种是主机名，另外一种是通过IP地址，这时就需要看业务了，如果业务不确定就使用IP地址，如果业务确定就用主机名（idc01-bj-product-node1.shop.com）,DNS解析主机名不支持下滑线

### 远程执行
	salt '*' test.ping		## 引起来是因为 * 在shell下也是有意义的

> test是一个模块，ping是这个模块下面的一个方法，它是python的标准；这个ping不是ICMP的ping，它是saltmaster和minion之间的一个通信，用的也不是ICMP的协议

	salt "linux-node1.example.com" cmd.run 'w'		## 命令一般也要引起来，方便传参
操作实例：

	[root@linux-node1 salt]# salt '*' cmd.run 'mkdir hehe'
	linux-node2.example.com:
	linux-node1.example.com:
	[root@linux-node1 salt]# salt '*' cmd.run 'ls -l'
	linux-node2.example.com:
	    total 4
	    -rw-------. 1 root root 1175 May 20 06:37 anaconda-ks.cfg
	    drwxr-xr-x  2 root root    6 Jun 25 21:01 hehe
	linux-node1.example.com:
	    total 4
	    -rw-------. 1 root root 1175 May 20 06:37 anaconda-ks.cfg
	    drwxr-xr-x  2 root root    6 Jun 25 21:01 hehe

后面可以通过ACL来控制权限，它很危险，可以执行删除操作

### 配置管理 

Salt通过状态模块来识别状态，要写一个关于状态的文件，它是一个YAML格式的文件，并且文件名后缀以 `.sls` 结尾。

[镜像文档](https://www.unixhot.com/docs/saltstack/index.html)

#### 理解YAML

> YAML是"YAML Ain't a Markup Language"（YAML不是一种置标语言）的递归缩写。它是类似于标准通用标记语言的子集XML的数据描述语言，语法比XML简单很多。因为它简单。
> 

三个规则

1. 缩进（代表层级关系，2个空格，并且不能使用TAB键，整个saltstack里面都不能用TAB键）
2. 冒号（1.跟缩进一起代理层级目录（以冒号结尾不用空格）；2.分隔键值对[key: value],支持嵌套，冒号后面必须有一个空格）
3. 短横线（它是一个列表，`-` 后面必须有空格）

> saltstack配置文件也是YAML语法。

#### 写一个模板文件

##### 编辑Master配置文件

/etc/salt/master
file_roots:

它是一个环境的定义，可以定义不同的路径，把不同业务放在不同的路径下，

	file_roots:			配置项
	  base:				配置base环境
	    - /srv/salt		可以写多个，它是个列表,base环境的根路径 

> base环境默认必须有，并且不能修改名字

重启master

	systemctl restart salt-master

创建目录

	mkdir /srv/salt -p
	cd /srv/salt
	mkdir web
	cd web
	cat >> apache.sls <<EOF
	apache-install:
	  pkg.installed:
	    - names:
	        - httpd
	        - httpd-devel
	
	apache-service:
	  service.running:
	    - name: httpd
	    - enable: True
	EOF

apache-install是定义的ID，pkg是一个状态模块，模块分为执行模块和状态模块，installed是模块方法

执行状态模块
<pre>
salt '*' state.sls web.apache
</pre>

/var/cache/salt/minion

master把文件发给minion,minion从上往下加载

出现的错误

<pre>
Salt request timed out. The master is not responding. If this error persists after verifying the master is up, worker_threads may need to be increased.
</pre>

> 已经有的是绿色，新完成的是浅绿色

### 对应关系文件

也是sls结尾，也是YAML。它放在base环境下，也就是这里的/srv/salt下
<pre>
# The state system uses a "top" file to tell the minions what environment to
# use and what modules to use. The state_top file is defined relative to the
# root of the base environment as defined in "File Server settings" below.
# state_top: top.sls
</pre>

	cat > top.sls <<EOF
	base:
	  'linux-node1.example.com':
	    - web.apache
	  'linux-node2.example.com':
	    - web.apache
	EOF

执行高级状态

	[root@linux-node1 salt]# salt '*' state.highstate
	linux-node2.example.com:
	----------
	          ID: apache-install
	    Function: pkg.installed
	        Name: httpd
	      Result: True
	     Comment: Package httpd is already installed
	     Started: 23:26:29.845158
	    Duration: 605.676 ms
	     Changes:   
	----------
	          ID: apache-install
	    Function: pkg.installed
	        Name: httpd-devel
	      Result: True
	     Comment: Package httpd-devel is already installed
	     Started: 23:26:30.450979
	    Duration: 0.433 ms
	     Changes:   
	----------
	          ID: apache-service
	    Function: service.running
	        Name: httpd
	      Result: True
	     Comment: The service httpd is already running
	     Started: 23:26:30.451937
	    Duration: 27.567 ms
	     Changes:   
	
	Summary for linux-node2.example.com
	------------
	Succeeded: 3
	Failed:    0
	------------
	Total states run:     3
	linux-node1.example.com:
	----------
	          ID: apache-install
	    Function: pkg.installed
	        Name: httpd
	      Result: True
	     Comment: Package httpd is already installed
	     Started: 23:26:29.999055
	    Duration: 608.856 ms
	     Changes:   
	----------
	          ID: apache-install
	    Function: pkg.installed
	        Name: httpd-devel
	      Result: True
	     Comment: Package httpd-devel is already installed
	     Started: 23:26:30.608080
	    Duration: 0.51 ms
	     Changes:   
	----------
	          ID: apache-service
	    Function: service.running
	        Name: httpd
	      Result: True
	     Comment: The service httpd is already running
	     Started: 23:26:30.609121
	    Duration: 35.008 ms
	     Changes:   
	
	Summary for linux-node1.example.com
	------------
	Succeeded: 3
	Failed:    0
	------------
	Total states run:     3

> 生产中不建议用* ,以后不能这样写命令，要先 `salt '*' state.highstate test=True` 


### SaltStack与ZeroMQ

ZeroMQ是一个消息队列，它不是传统意义上的消息队列，它是一个传输层的库，
它有几种模式：

##### 发布与定阅模式（Publish/Subscribe）简称Pub/Sub

所有的minion都会连到4505端口，而且是TCP的长连接

salt '*' cmd.run 'w'


#####请求与响应模式

默认监听4506端口，返回结果的时候通过4506端口，

把进程的标题显示出来

<pre>
yum install -y python-setproctitle
systemctl restart salt-master
ps -ef|grep salt-mast
</pre>

[有一篇文章](https://www.unixhot.com/uploads/article/20151027/055f24981e25860e08942d7f0aa9d0ab.png)


### Saltstack的数据系统

两种数据系统


*　Grains（谷粒）
*　Pillar（柱子）

Grains是静态数据，它是在Minion启动的时候收集的Minion本地的相关信息，如：操作系统版本，内核版本，ＣＰＵ，内存，硬盘，设备型号，机器序列号。它可以做资产管理，只要不重启它，它就会只收集一次，当重启的时候才会再次收集，启动完后就不会变了,它是一个key/value的东西。

作用：

* 资产管理、信息查询
* 用于目标选择（不同于ID的另外目标定义方法，操作系统等）
* 配置管理中使用

#### 信息查询

查看所有信息
<pre>
salt 'linux-node1.example.com' grains.ls
salt 'linux-node1.example.com' grains.items
salt '*' grains.item os
salt '*' grains.item fqdn_ip4
</pre>

#### 目标选择

-G 参数

<pre>
salt -G 'os:CentOS' test.ping
salt -G 'os:CentOS' cmd.run 'echo hehe'
</pre>

可以给某一个minion自定义一个grains，然后再来找它，方法：写配置文件，有两种办法来存放 它
<pre>
vim /etc/salt/minion
grains:
  roles: apache 
systemctl restart salt-minion
[root@linux-node1 salt]# salt '*' grains.item roles
linux-node2.example.com:
    ----------
    rolesode1.example.com:
    ----------
    roles:
[root@linux-node1 salt]# salt '*' grains.item roles
linux-node1.example.com:
    ----------
    roles:
linux-node2.example.com:
    ----------
    roles:
        apache:
</pre>

重启所有apache

	salt -G 'roles:apache' cmd.run 'systemctl restart httpd'

> 生产不建议放在minion配置文件里面，写在 `/etc/salt/grains` 里面，minion会自动来这找；并且上面这条命令中的roles:后面是没有空格的


	cloud: openstack
	salt '*' grains.item cloud

> 加完之后必须重启，因为它是静态的。但不重启也有一个刷新的命令 `salt '*' saltutil.sync_grains` 无论上面两种方法写在哪都可以成功。

#### top file使用案例
grains还可以用到top.sls文件里面

<pre>
base:
  'linux-node1.example.com':
    - web.apache
  'roles:apache': 
    - match: grain 
    - web.apache
</pre>


#### 配置管理的案例

vim /srv/salt/web/apache.sls


> 可以自己用python脚本来写一个grains，实现动态，这里说的动态是通过逻辑后产生的

#### 用Python开发一个grains

写一个python脚本返回一个字典就可以了。

1. 放哪儿
	1. cd /srv/salt/
	2. mkdir _grains
	3. cd _grains
2. 写脚本
	1. vim my_grains.py
<pre>
#!/usr/bin/env python
#-*- coding: utf-8 -*-

def my_grains():
    # 初始化一个grains字典
    grains = {}
    # 设置字典中的key/value
    grains['iaas'] = 'openstack'
    grains['edu'] = 'example'
    # 返回这个字典
    return grains
</pre>

3. 把grains推送给minion
<pre>
salt '*' saltutil.sync_grains
它会放在/var/cache/salt/minion/extmods/grains/my_grains.py
</pre>
4. 查看

<pre>
salt '*' grains.item iaas
</pre>

Grains优先级：

1. 系统自带
2. grains文件写的
3. minion配置文件写的
4. 自己写的



### pillar

它也是数据系统，也是key/value，但是pillar数据是动态的，和minion启不启动没关系，它给特定的minion指定特定的数据，跟top file很像。只有指定的minion自己能看到自己的数据。

查看pillar

	salt '*' pillar.items

vim /etc/salt/master
646  注释去掉。改成True


systemctl restart salt-master



pillar_toots  topfile.sls
<pre>
vim /etc/salt/master
642行
pillar_roots:
  base:
    - /srv/pillar

mkdir /srv/pillar
cd /srv/pillar
mkdir web
cd web
vim apache.sls
{% if grains['os'] == 'CetnOS' %}
apache: httpd
{% elif grains['os'] == 'Debian' %}
apache: apache2
{% endif %}
</pre>

1. 写pillar的sls
2. 写topfile(pillar必须要写topfile,不像配置管理不用也可以)

<pre>
salt '*' saltutil.refresh_pillar
salt '*' pillar.items apache
</pre>

vim apache.sls
	hehe:
		{% if grains['os'] == 'CetnOS' %}
		apache: httpd
		{% elif grains['os'] == 'Debian' %}
		apache: apache2
		{% endif %}

salt '*' saltutil.refresh_pillar
salt '*' pillar.items hehe


#### 使用场景

1. 目标选择
	1. salt -I 'apache:httpd' test.ping


这四种方式的匹配主要是为了在多机器环境下灵活地匹配主机

### Grains VS Pillar

Grains:		类型		数据采集方式				应用场景						定义位置

Grains		静态		minion启动时收集		数据查询、目标选择、配置管理		minion端


	
Pillar		动态		master自定义			目标选择、配置管理、敏感数据存储	master端


## 远程执行

深入学习SaltStack远程执行

salt '*' cmd.run 'w'

命令：salt

目标： '*'（好多种方式指定）

模块：cmd.run   自带150+模块。可以自己写模块

返回：可以写入数据库里面，执行后结果返回，通过Returnners组件

#### 目标Targeting

你要指定哪个或者哪些minion来执行后面的东西 ，怎么来定位？

两种定位的方法：
1. 和minion id有关的
2. 和Minion_id无关的

##### 有关的

1. Minion id(linux-node1.example.com)
2. 通配符(*/linux-node**/linux-node[1|2].example.com/linux-node?.example.com)
3. 列表：（salt -L 'linux-node1.example.com,linux-node2.example.com' test.ping）
4. 正则表达式：（salt -E 'linux-(node1|node2)*' test.ping|salt -E 'linux-(node1|node2).example.com' test.ping）

> 所有匹配目标的方式都可以用在top file里面来指定目标 


##### 无关的

主机名设置方案：

1. IP地址
2. 根据业务来进行设置

<pre>
redis-node1-redis03-idc03-soa.example.com
</pre>

redis-node1  redis第一个节点

redis04   集群

idc04   机房

soa	业务线

  
子网和IP地址
<pre>
salt -S 192.168.56.11 test.ping
salt -S 192.168.56.0/24 test.ping
</pre>

##### NODE GROUPS

vim /etc/salt/master
/nodegroup

nodegroups:
  web: 'L@linux-node1.example.com,linux-node2.example.com'
systemctl restart salt-master
salt -N web test.ping

##### 混合匹配 

https://www.unixhot.com/docs/saltstack/topics/targeting/compound.html

##### 批处理

可以通过百分比来执行

#### 模块

saltstack内置了丰富的模块来执行,每一个模块都是一个python文件，挑几个来学习

###### NETWORK

	salt '*' network.active_tcp
	salt '*' network.arp


###### SERVICE

	salt '*' service.available sshd
	salt '*' service.get_all

###### CP

	salt-cp '*' /etc/hosts /tmp/hehe

###### STATE

	salt '*' state.show_top
	salt '*' state.single pkg.installed name=lsof

### 返回程序

把返回结果写到数据库里面

salt使用返回程序来实现这些功能(returnners)
##### SALT.RETURNERS.MYSQL

Returnn data to mysql server

这个返回数据是minion直接返回的，所有的minion要装python的MySQL 库

我们使用salt装

<pre>
salt '*' state.single pkg.installed name=MySQL-python
yum install mariadb-server mariadb -y
systemctl start mariadb
</pre>

<pre>
mysql
CREATE DATABASE  `salt`
  DEFAULT CHARACTER SET utf8
  DEFAULT COLLATE utf8_general_ci;
USE `salt`;
CREATE TABLE `jids` (
  `jid` varchar(255) NOT NULL,
  `load` mediumtext NOT NULL,
  UNIQUE KEY `jid` (`jid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
CREATE INDEX jid ON jids(jid) USING BTREE;
CREATE TABLE `salt_returns` (
  `fun` varchar(50) NOT NULL,
  `jid` varchar(255) NOT NULL,
  `return` mediumtext NOT NULL,
  `id` varchar(255) NOT NULL,
  `success` varchar(10) NOT NULL,
  `full_ret` mediumtext NOT NULL,
  `alter_time` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  KEY `id` (`id`),
  KEY `jid` (`jid`),
  KEY `fun` (`fun`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
CREATE TABLE `salt_events` (
`id` BIGINT NOT NULL AUTO_INCREMENT,
`tag` varchar(255) NOT NULL,
`data` mediumtext NOT NULL,
`alter_time` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
`master_id` varchar(255) NOT NULL,
PRIMARY KEY (`id`),
KEY `tag` (`tag`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
grant all on salt.* to salt@'%' identified by 'salt@pw';
flush privileges;
mysql -h 192.168.56.11 -usalt -psalt@pw
</pre>

修改minion配置文件
<pre>
vim /etc/salt/minion
mysql.host: '192.168.56.11'
mysql.user: 'salt'
mysql.pass: 'salt@pw'
mysql.db: 'salt'
mysql.port: 3306
systemctl restart salt-minion
</pre>

执行结果：
<pre>
[root@linux-node1 salt]# salt '*' test.ping --return mysql
linux-node2.example.com:
    True
linux-node1.example.com:
    True
[root@linux-node1 salt]# mysql
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 8
Server version: 5.5.47-MariaDB MariaDB Server

Copyright (c) 2000, 2015, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]> use salt;
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Database changed
MariaDB [salt]> show tables;
+----------------+
| Tables_in_salt |
+----------------+
| jids           |
| salt_events    |
| salt_returns   |
+----------------+
3 rows in set (0.00 sec)

MariaDB [salt]> select * from salt_returns;
+-----------+----------------------+--------+---------------------------+---------+-------------------------------------------------------------------------------------------------------------------------------------------------------+---------------------+
| fun       | jid                  | return | id                        | success | full_ret                                                                                                                                              | alter_time          |
+-----------+----------------------+--------+---------------------------+---------+-------------------------------------------------------------------------------------------------------------------------------------------------------+---------------------+
| test.ping | 20160626025439671711 | true   | linux-node2.example.com | 1       | {"fun_args": [], "jid": "20160626025439671711", "return": true, "retcode": 0, "success": true, "fun": "test.ping", "id": "linux-node2.example.com"} | 2016-06-26 02:54:39 |
| test.ping | 20160626025439671711 | true   | linux-node1.example.com | 1       | {"fun_args": [], "jid": "20160626025439671711", "return": true, "retcode": 0, "success": true, "fun": "test.ping", "id": "linux-node1.example.com"} | 2016-06-26 02:54:39 |
+-----------+----------------------+--------+---------------------------+---------+-------------------------------------------------------------------------------------------------------------------------------------------------------+---------------------+
2 rows in set (0.00 sec)
</pre>

### 编写一个执行模块

vim /usr/lib/python2.7/site-packages/salt/modules/service.py

编写模块：

1. 放哪（cd /srv/salt/_modules）
2. 命名（文件名就是模块名，如my_disk.py）
<pre>
[root@linux-node1 _modules]# cat my_disk.py 
#!/usr/bin/env python

def list():
  cmd = 'df -h'
  ret = __salt__['cmd.run'](cmd)
  return ret
</pre>

刷新

	salt '*' saltutil.sync_modules

<pre>
[root@linux-node2 ~]# tree /var/cache/salt/minion/
/var/cache/salt/minion/
├── accumulator
├── extmods
│   ├── grains
│   │   ├── my_grains.py
│   │   └── my_grains.pyc
│   └── modules
│       └── my_disk.py
├── files
│   └── base
│       ├── _grains
│       │   └── my_grains.py
│       ├── _modules
│       │   └── my_disk.py
│       ├── top.sls
│       └── web
│           └── apache.sls
├── highstate.cache.p
├── module_refresh
├── pkg_refresh
├── proc
└── sls.p

[root@linux-node1 _modules]# salt '*' my_disk.list
linux-node2.example.com:
    Filesystem      Size  Used Avail Use% Mounted on
    /dev/sda3       196G  2.1G  194G   2% /
    devtmpfs        480M     0  480M   0% /dev
    tmpfs           489M   12K  489M   1% /dev/shm
    tmpfs           489M  6.7M  483M   2% /run
    tmpfs           489M     0  489M   0% /sys/fs/cgroup
    /dev/sda1       497M  128M  370M  26% /boot
    tmpfs            98M     0   98M   0% /run/user/0
linux-node1.example.com:
    Filesystem      Size  Used Avail Use% Mounted on
    /dev/sda3       196G  2.3G  194G   2% /
    devtmpfs        480M     0  480M   0% /dev
    tmpfs           489M   40K  489M   1% /dev/shm
    tmpfs           489M  6.8M  483M   2% /run
    tmpfs           489M     0  489M   0% /sys/fs/cgroup
    /dev/sda1       497M  128M  370M  26% /boot
    tmpfs            98M     0   98M   0% /run/user/0
</pre>

<div style="width:100px;height:100px;box-shadw:0px 0px 3px #000;>
		<img src="https://github.com/Aresona/edu-docs/blob/master/image/touxiang.jpg" />
</div>


作业
预习配置管理

https://github.com/unixhot