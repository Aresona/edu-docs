# 配置（状态）管理

状态是可以多次执行的，也就是说每一次执行状态它都会执行命令。如果你写的是一个安装软件的命令，每一次执行它也会执行。当使用 `cmd.run` 的时候它也会多次执行，如创建目录。如果使用状态管理的时候，它会检测有没有，没有才创建。
## SLS文件

SLS是 `Salt State` 的缩写，它是一个描述文件，也是状态系统的核心，默认是YAML格式（也可以用其他语言）。因为它是python语言写的，解析的时候需要的参数是一个字典，所以不管什么语法只要最后能解析成一个字典就可以。
### 配置文件说明
	[root@linux-node1 web]# cat apache.sls 
	apache-install:		## ID（名称）配置项声明，并且默认是name声明
	  pkg.installed:	## Stage声明  状态声明
	    - names:		## 选项声明
	        - httpd
	        - httpd-devel
	
	apache-service:
	  service.running:
	    - name: httpd
	    - enable: True

> 高级状态中，ID必须唯一；无论什么时候我们在使用的时候也最好保持ID唯一，不管是不是在同一个模板中。

[highstate官方文档](https://www.unixhot.com/docs/saltstack/ref/states/highstate.html)

> 一个状态声明中只能包含一次函数声明

## 模块说明
#### pkg模块

	Installation of packages using OS package managers such as yum or apt-get
pkg是一个虚拟模块，也就是它会根据不同的操作系统来用不同的包管理器安装相关的包

##### installed		

* sources
<pre>
yum_repo_release:
  pkg.installed:
    - sources:
      - epel-release: http://mirrors.aliyun.com/epel/epel-release-latest-7.noarch.rpm
</pre>
> epel-release将会在下载时显示，代表仓库的名称；在sources下面可以写多个源。

##### group_installed

安装组

##### latest

确保软件包是最新版本，如果不是就升级

##### removed 	

确保软件包是被卸载的


##### purged

	除了会把软件包卸载外还会把配置文件都删除掉

> `installed` 方法有一个 `- fromrepo` 参数可以指定安装的repo文件，当然它需要跟 `pkgrepo.managed` 配合使用

#### file模块

Salt States可以积极地操作一个系统上的文件，一般文件可以被 `file.managed`强制执行；它首先从master端把文件下载下来，然后再替换掉原来的文件；我们可以在文件里面使用jinja等模板实现动态生成，
##### managed

* name
* source
<pre>salt://xxx/files/xxx.conf</pre>
* user
* group
* mode

##### append

* text    追加内容
<pre>
/etc/profile:
  file.append:
    - text:
      - export HISTTIMEFORMAT="%F %T `whoami`"
</pre>

##### directory

* user
* group
* mode
* makedirs
* recurse
* file_mode
* dir_mode

> 这个模块是用来管理目录的，它能创建和指定固定权限

##### symlink
<pre>
/etc/grub.conf
  file.symlink:
    - target: /boot/grub/grub.conf
</pre>

#### service模块

service状态通过 `minion` 端支持的服务模块来管理服务。另外,salt的执行模块和这个服务状态都是通过系统grains来确实哪个状态模块应该被加载并使用。所以一些特殊的系统可能会不准确。

系统当前的状态取决于 `init/rc` 状态命令返回的编码，如果是0就代表正在运行。

##### running

* enalbe
* reload
* watch

> watch主要用来当配置文件变化的时候重启该服务

> 一个ID声明下面，一个状态模块不能重复使用,只能用一次

#### sysctl
##### present
<pre>
net.ipv4.ip_local_port_range:
  sysctl.present:
    - value: 10000 65000
</pre>

> 这个模块只有这一个方法，并且这个模块只能用来设置linux内核参数，也就是 `/etc/sysctl.conf` 这个文件。

### 状态间的依赖关系
1. 我依赖谁	require
2. 我被谁依赖		require_in
3. 我监控谁		watch
4. 我被谁监控		watch_in
5. 我引用谁		include
6. 我扩展谁

#### Require
<pre>
apache-service:
  service.running:
    - name: httpd
    - enable: True
    - reload: True
    - require:
      - pkg: lamp-pkg
      - file: apache-config 
</pre>
<pre>
mysql-config:
  file-managed:
    - name: /etc/my.cnf
    - source: salt://lamp/files/my.cnf
    - user: root
    - group: root
    - mode: 644
    - require_in:
      - service: mysql-service 
</pre>
这里表示 `apache-service` 依赖安装包及配置文件，写法如下： `状态模块: ID`;另外在不同的sls之间也是可以调用的。
#### Watch

<pre>
apache-service:
  service.running:
    - name: httpd
    - enable: True
    - reload: True
    - require:
      - pkg: lamp-pkg
    - watch:
      - file: apache-config 
</pre>
修改端口号测试有没有变化
<pre>
salt 'linux-node2*' state.sls lamp.init
</pre>
1. 如果apche-config 这个ID的状态发生变化就reload
2. 如果不加reload=True的话就restart
3. 以前必须学，现在就不那么重要了，因为现在有顺序了。
4. **watch包括require。**
#### Include

首先写几个不同功能的SLS文件，如 `pkg.sls`、`config.sls`、`service.sls`。然后写一个总的文件来包含它们
<pre>
vim init.sls
include:
  - lamp.pkg
  - lamp.config
  - lamp.service

salt 'linux-node2*' state.sls lamp.init
</pre>

> 这样写有一个好处就是别人也可以依赖，也就是原子化

####  编写SLS技巧

1. 按状态分类，如果单独使用，很清晰（pkg/config/service）
2. 服务分类，可以被其他的SLS include.例如LNMP include mysql的服务。


## 写一个LAMP架构的配置管理文件
### 规划：

1. 安装软件包
2. 修改配置文件
3. 启动服务

> 上面这三个对应了三种状态模块，分别是pkg、file、service模块

[状态管理的官方文档](https://www.unixhot.com/docs/saltstack/ref/states/all/index.html)
### 目录规划

<pre>
mkdir /srv/salt/lamp -p
cd /srv/salt/lamp
touch lamp.sls
mkdir files
cd files
cp /etc/httpd/conf/httpd.conf .
cp /etc/php.ini .
cp /etc/my.cnf .
</pre>

### LAMP架构
#### 写sls文件

	cd /srv/salt/
	mkdir lamp
	cd lamp
	cat > lamp.sls <<EOF
	lamp-pkg:
	  pkg.installed:
	    - pkgs:
	      - httpd
	      - php
	      - mariadb
	      - mariadb-server
	      - php-cli
	      - php-mbstring

	apache-config:
      file.managed:
        - name: /etc/httpd/conf/httpd.conf
        - source: salt://lamp/files/httpd.conf
        - user: root
        - group: root
        - mode: 644

    php-config
      file.managed:
        - name: /etc/php.ini
        - source: salt://lamp/files/php.ini
        - user: root
        - group: root
        - mode: 644

    mysql-config:
      file-managed:
        - name: /etc/my.cnf
        - source: salt://lamp/files/my.cnf
        - user: root
        - group: root
        - mode: 644
    
	apache-service:
      service.running:
	    - name: httpd
	    - enable: True
	    - reload: True

	mysql-service:
	  service.running:
	    - name: mariadb
	    - enable: True
	    - reload: True
	EOF
</pre>

执行

<pre>
	cd /srv/salt/lamp
	mkdir files
	cp /etc/my.cnf .
	cp /etc/httpd/conf/httpd.conf .
	cp /etc/php.ini .
	salt 'linux-node2*' test.ping
	salt 'linux-node2*' state.sls lamp.lamp 
</pre>
<pre>salt:// 表示当前环境的根目录，这里的当前环境是指 `base` 或者 `dev` 这样的环境。这些路径可以去 `/etc/salt/master` 文件里面查看</pre>
> 生产中的配置文件一般都是先安装完软件后再把配置文件复制过来，不可能自己手写。

<pre>排错思路：salt的新版本可能会有缓存的问题，一般看这个的时候可以查看minion的日志，看它是否有输出，如果没有输出就说明是在用cache,如果它确实是在用缓存的话可能通过重启minion来解决。</pre>

#### 按服务分类规划SLS文件
关于SLS文件的规划其实是有两种类型，或者更多类型，一种是上面这种，把安装、配置、启动分开；另外一种是把服务分开，也就是说每个服务的安装、配置、启动放在一个文件里面，也就是按服务分类；默认推荐第二种方式 。如下：
<pre>
mysql-service:
  - service.running:
    - name: mariadb-server
    - enable: True
    - reload: True

apache-server:
  pkg.installed:
    - pkgs:
      - httpd
      - php
  file.managed:
    - name: /etc/httpd/conf/httpd.conf
    - source: salt://lamp/files/httpd.conf
    - user: root
    - group: root
    - mode: 644
  service.running:
    - name: httpd
    - enable: True
    - reload: True
 
mysql-server:
  pkg.installed:
    - pkgs:
      - mariadb-server
      - mariadb
  file.managed:
    - name: /etc/my.cnf
    - source: satl://lamp/files/my.cnf
    - user: root
    - group: root
      - mode: 644
  service.running:
    - name: mariadb-server
    - enable: True
    - reload: True

php-config:
  file.managed:
    - name: php.ini
    - source: salt://lamp/files/php.ini
    - user: root
    - gorup: root
    - mode: 644
</pre>

**注意**

1. sls解析模式是从上往下。也就是如果有逻辑的话一定要注意，如安装上之后才能启动；最开始的时候salt是乱序，不是严格意义上的从上往下。
2. 第一条还有一个隐藏的属性就是当上面的执行失败的时候，下面的还是会执行，这在有些时候会出问题，所以就需要延伸到下面的状态间关系了。

## jinja模板

[jinja模板](http://docs.jinkan.org/docs/jinja2)是一个python的模板语言.严格意义上来说，它叫做 `yaml-jinja`,我们也可以用其他模板。模板仅仅是文本文件。它可以生成任何基于文本的格式（HTML、XML、CSV、LaTex 等等）。 它并没有特定的扩展名， .html 或 .xml 都是可以的。

模板包含 变量 或 表达式 ，这两者在模板求值的时候会被替换为值。模板中 还有标签，控制模板的逻辑。模板语法的大量灵感来自于 Django 和 Python 。

这里有两种分隔符: `{% ... %}` 和 `{{ ... }}` 。前者用于执行诸如 for 循环 或赋值的语句，后者把表达式的结果打印到模板上。
### 功能
假如想要在配置文件里面加一个本地的IP地址，这时候就可以通过这个模板来替换某一些东西。也就是它可以实现变量的功能。

**在模板中设置自定义变量**
<pre>
{% set variable_name = value %}
</pre>
比如设置
<pre>{% set username = 'Jack' %}</pre>

  那么在设置之后就可以使用 `{{ username }}` 得到输出Jack
### 简单使用
在SLS文件里面把端口号指定为一个变量，也就是在SLS文件里面指定端口号，而不是在配置文件里面

使用模板需要三步：

* 告诉 `file` 模块，你要使用 `jinja`
<pre>
vim /srv/salt/lamp/config.sls
apache-config:
  file.managed:
    - name: /etc/httpd/conf/httpd.conf
    - source: salt://lamp/files/httpd.conf
    - user: root
    - group: root
    - mode: 644
    - template: jinjja
</pre>
* 列出参数列表

<pre>
apache-config:
  file.managed:
    - name: /etc/httpd/conf/httpd.conf
    - source: salt://lamp/files/httpd.conf
    - user: root
    - group: root
    - mode: 644
    - template: jinjja
    - defaults:
      PORT: 88
</pre>

* 模板的引用　

<pre>
vim /srv/salt/lamp/files/httpd.conf
Listen {{ PORT }}
</pre>

执行：

	 salt 'linux-node2*' state.sls lamp.init

#### jinja模板支持 `salt/grains/pillar` 进行引用(赋值)

##### Grains
<pre>
Listen {{ grains['fqdn_ip4'] }}:{{ PORT }}
Listen {{ grains['ipv4'][1] }}:{{ PORT }}
Listen {{ grains['ipv4'][1][-1] }}:{{ PORT }}
Listen {{ grains['fqdn_ip4'][0] }}:{{ PORT }}
</pre>

> grains 默认取到的值是列表的格式，如 `['192.168.1.1']`

###### 取IP(从列表里面取到第一个值)

<pre>Listen {{ grains['fqdn_ip4'][0] }}:{{ PORT }}</pre>

<pre>
[root@linux-node1 ~]# salt 'linux-node1*' grains.item fqdn_ip4
linux-node1.oldboyedu.com:
    ----------
    fqdn_ip4:
        - 192.168.56.11 
它是通过 `/etc/hosts` 文件来解析的
[root@linux-node1 ~]# salt 'linux-node1*' grains.item ipv4
linux-node1.oldboyedu.com:
    ----------
    ipv4:
        - 127.0.0.1
        - 192.168.56.11
它是通过网卡来获取的
</pre>
##### Salt
<pre>{{ salt['netwrok.hw_addr']('eth0') }}
salt '*' network.hw_addr eth0</pre>
> 这里使用的是salt远程执行模块
##### pillar

<pre>{{ pillar['apache'] }}</pre>

这个用途一般用于配置用户名密码的时候

<pre>username: {{ pillar['apache'] }}</pre>
#### SLS文件里面添加变量
上面这种方法有一个缺点就是我如果想看我在配置文件里面加了哪些变量的话还需要去配置文件里面一个一个的看，所以还有一种方法就是写在SLS文件里面，这样就可以很明显地看到有哪些东西是改了的。

<pre>
SLS文件里面：
USERNAME: {{ pillar['apache'] }}
配置文件里面：
username {{ USERNAME }}
</pre>
这样一看就能知道配置文件里面到底配了多少变量

[saltstack文件](https://github.com/saltstack-formulas)

> 不只可以在配置文件里面使用JINJA模板的变量，在SLS文件里面也可以使用(`{% from "php/map.jinja" import php with context %}`)


# 生产案例
## 架构
![](https://github.com/Aresona/edu-docs/blob/master/image/SaltStack/saltstack-arch.png?raw=true)
## 规划
1. 系统初始化
2. 每个服务单独写SLS文件，也就是写功能模块：设置单独的目录(haproxy/nginx/php/mysql/memcache),这里把单独的目录称之为一个模块。
3. 业务模块：根据业务类型划分，例如对于nginx配置文件来说，要分开web服务，论坛，bbs等不同的业务来管理。

> 在功能模块里面做到全和独立，然后在业务模块里面直接 `include` 就可以了。
## Actions
### salt环境配置
开发、测试（功能测试环境、性能测试环境）、预生产、生产
> 这里可以满足生产中各种环境的分类，每个环境的东西都不一样，所以需要不同的环境，也方便管理，saltstack默认必须有一个base环境，所以这里面我们可以写一些各种环境里面都一样的东西，如系统初始化的一些东西。
<pre>
/etc/salt/master
file_roots:
  base:
    - /srv/salt/base 
  prod:
    - /srv/salt/prod 

pillar_roots:
  base:
    - /srv/pillar/base
  prod:
    - /srv/pillar/prod 
mkdir -p /srv/salt/base
mkdir -p /srv/salt/prod
mkdir -p /srv/pillar/base
mkdir -p /srv/pillar/prod
systemctl restart salt-master
</pre>

### base 基础环境

#### 规划init目录

<pre>
cd /srv/salt/base
mkdir init/files -p
cd init
</pre>
#### 系统初始化模块
* DNS配置  
* history记录时间  
* 记录命令操作
* 内核参数优化
* 安装YUM仓库
* 安装zabbix-agent
##### DNS
<pre>
cp /etc/resolv.conf files/
echo "/etc/resolv.conf:
  file.managed:
    - source: salt://init/files/resolv.conf
    - user: root
    - gourp: root
    - mode: 644" > dns1.sls
</pre>
##### History记录时间
<pre>
echo '/etc/profile:
  file.append:
    - text:
      - export HISTTIMEFORMAT="%F %T `whoami` "' > history.sls
</pre>

backup: minion

##### 记录命令操作
<pre>
cat audit.sls 
/etc/bashrc:
  file.append:
    - text:
      - export PROMPT_COMMAND='{ msg=$(history 1 | { read x y; echo $y; });logger "[euid=$(whoami)]":$(who am i):[`pwd`]"$msg"; }'
</pre>

##### 内核参数优化
<pre>
[root@linux-node1 init]# cat sysctl.sls 
net.ipv4.ip_local_port_range:
  sysctl.present:
    - value: 10000 65000
fs.file-max:
  sysctl.present:
    - value: 2000000
net.ipv4.ip_forward:
  sysctl.present:
    - value: 1
vm.swappiness:
  sysctl.present:
    - value: 0
</pre>

* 本地可用的端口范围
作为客户端发起连接(socket)的时候，socket是五元组（源地址、源端口、目的端口、目的地址、协议）
* 打开文件数限制
linux下一切皆文件，也就是TCP连接也是一个文件，一个连接也会占用一个文件。
<pre>cat /proc/sys/fs/file-max</pre>
* 使用交换分区的权重值
<pre>cat /proc/sys/vm/swappiness</pre>
默认centos7是30
##### 安装YUM仓库
<pre>
echo "yum_repo_release:
  pkg.installed:
    - sources:
      - epel-release: http://mirrors.aliyun.com/epel/epel-release-latest-7.noarch.rpm
      - zabbix-release: http://repo.zabbix.com/zabbix/3.0/rhel/7/x86_64/zabbix-release-3.0-1.el7.noarch.rpm" > epel.sls
</pre>

##### 安装zabbix-agent
<pre>
[root@linux-node1 init]# cat zabbix_agent.sls 
zabbix-agent:
  pkg.installed:
    - name: zabbix-agent
  file.managed:
    - name: /etc/zabbix/zabbix_agentd.conf
    - source: salt://init/files/zabbix_agentd.conf
    - template: jinja
    - backup: minion
    - defaults:
      Zabbix_Server: {{ pillar['Zabbix_Server'] }}
      Hostname: {{ grains['fqdn']}}
    - require:
      - pkg: zabbix-agent
  service.running:
    - enable: True
    - watch:
      - pkg: zabbix-agent
      - file: zabbix-agent
zabbix_agentd.conf.d:
  file.directory:
    - name: /etc/zabbix/zabbix_agentd.d
    - watch_in:
      - service: zabbix-agent
    - require:
      - pkg: zabbix-agent
      - file: zabbix-agent
</pre>
<pre>
cp /etc/zabbix/zabbix_agentd.conf files/
## EDIT zabbix_agentd.conf
Include=/etc/zabbix/zabbix_agentd.d/
Server={{ Zabbix_Server }}
Hostname= {{ Hostname }}
</pre>
> 在生产中，不要用*来匹配机器，一般先通过 `test=True` 来检查，如果没事，就给一台机器先部署，如果再没问题才部署所有的机器。
##### Pillar配置
<pre>
cd /srv/salt/pillar/base
mkdir zabbix
cd zabbix
[root@linux-node1 zabbix]# cat agent.sls 
Zabbix_Server: 192.168.56.11
[root@linux-node1 zabbix]# cd ..
[root@linux-node1 base]# cat top.sls 
base:
  '*':
    - zabbix.agent
</pre>

#### prod 生产环境

<pre>
cd /srv/
unzip salt.zip

</pre>

本地可用的端口范围：用作客户端发起连接的时候用到的范围，socket是五无组（源地址、源端口、目的地址、目的端口、协议）

<pre>
cd /srv/salt/prod
mkdir haproxy
mkdir keepalived
mkdir nginx
mkdir php
mkdir memcached
mkdir pkg
</pre>

<pre>
cd pkg
vim make.sls
make-pkg:
  pkg.installed:
    - pkgs:
      - gcc
      - gcc-c++
      - glibc
      - make
      - autoconf
      - openssl
      - openssl-devel
      - pcre
      - pcre-devel
</pre>
<pre>
cd haproxy
mkdir files
上传包
cp 
cd /usr/local/src
wget http://www.haproxy.org/download/1.6/src/haproxy-1.6.3.tar.gz
tar xf haproxy-1.6.3.tar.gz
cd /usr/local/src/haproxy-1.6.3
make TARGET=linux2628 PREFIX=/usr/local/haproxy-1.6.3
make install PREFIX=/usr/local/haproxy
ln -s /usr/local/haproxy-1.6.3/ /usr/local/haproxy
cp /usr/local/sbin/haproxy /usr/sbin/
#mkdir -p /etc/haproxy/
cd /etc/haproxy
</pre>
zip -r a.zip a

默认是base环境

<pre>salt '*' state.sls haproxy-install saltenv=prod</pre>


#### 业务层面引用

<pre>
cd /srv/salt/prod
mkdir modules
mv * modules
mkdir cluster
cd cluster

</pre>


## 继续学习状态间关系

* unless


* onlyif

> 它们的区别就是反着的，



## salt安装自动化

可以写个sls来部署saltstack，因为salt支持salt-call命令













配置管理跟远程执行比较像，需要学习状态模块，还有就是学习saltstack需要架构能力，把架构写一遍，用自己学习的saltstack技术来学习这个技术。后面的内容还有saltstack双主的架构，salstack ssh的能力，saltstack api的东西 。









## 作业

rsyslog  一个环境里面有一个server端，它跟客户端的配置是不一样的，如果管理配置文件的话，怎么除掉pillar是哪两台的机器

所有的minion中除去pillar中item rsyslog的值是server的minion

<pre>salt -C '* and not web-dc1-srv' test.ping</pre>
先通过pillar把服务器端定义出来，然后再通过混合匹配把它摘除掉。













##### 架构师必备

网络、系统、数据库、云计算、自动化、架构、开发、安全
> 交换机解决的是冲突域，路由器解决的是广播域
