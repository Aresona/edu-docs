# 状态管理

## SLS

SLS是 `Salt State` 的缩写，它是一个描述文件，默认是YAML格式。salt最终执行的时候是一个字典的格式。

	[root@linux-node1 web]# cat apache.sls 
	apache-install:		## ID（名称）声明，并且默认是name声明
	  pkg.installed:	## Stage声明  状态声明
	    - names:		## 选项声明
	        - httpd
	        - httpd-devel
	
	apache-service:
	  service.running:
	    - name: httpd
	    - enable: True

> 高级状态中，ID必须唯一。

https://www.unixhot.com/docs/saltstack/ref/states/highstate.html

### 写一个LAMP架构的配置管理文件

规划：

1. 安装软件包
2. 修改配置文件
3. 启动服务

> 上面这三个对应了三种状态模块，分别是pkg/file/service

[相关文档](https://www.unixhot.com/docs/saltstack/ref/states/all/index.html)

> 交换机解决的是冲突域，路由器解决的是广播域

#### pkg模块

* installed		安装
* group_installed
* latest		确保最新版本
* remove 	卸载
* purged（会把软件包和配置文件都删除掉）卸载并删除配置文件

##### installed

pkgs    同时安装多个包

#### file模块

* managed

#### service模块

* running

enable/reload

#### LAMP架构


> 一个ID声明下面，一个状态模块不能重复使用


建立相关目录

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
	    - name: mariadb-server
	    - enable: True
	    - reload: True
	EOF

	cd /srv/salt/lamp
	mkdir files
	cp /etc/my.cnf .
	cp /etc/httpd/conf/httpd.conf .
	cp /etc/php.ini .
	salt 'linux-node2*' test.ping
	salt 'linux-node2*' state.sls lamp.lamp 

另外一种写法：

<pre>
lamp-pkg:
  pkg.installed:
    - pkgs:
      - httpd
      - php
      - mariadb
      - mariadb-server
      - php-cli
      - php-mbstring
</pre>

> sls解析模式是从上往下。最开始的时候salt是乱序，



#### 状态间的依赖关系
1. 我依赖谁	require
2. 我被谁依赖		require_in
3. 我监控谁		watch
4. 我被谁监控		watch_in
5. 我引用谁
6. 我扩展谁

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

<pre>
只要状态发生变化就做相应的操作
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
> 如果apche-config 这个ID的状态发生变化就reload，如果不加reload=True的话就restart

<pre>
include:
  - lamp.pkg
</pre>


####  如何编写SLS技巧

1. 按状态分类，如果单独使用，很清晰
2. 服务分类，可以被其他的SLS include.例如LNMP include mysql的服务。


改一下端口号
<pre>
salt 'linux-node2*' state.sls lamp.init
</pre>

## jinja模板

它是一个python的模板语言，如想要在配置文件里面加一个本地的IP地址，这时候就可以通过这个模板来实现。

严格意义上来说，它是yaml--jinja

1. 在模板中设置自定义变量：
<pre>
{% set variable_name = value %}
</pre>
比如设置
<pre>{% set username = 'Jack' %}</pre>

  那么在设置之后就可以使用 `{{ username }}` 得到输出Jack
### 使用

在SLS文件里面指定端口号，而不是在配置文件里面

使用模板需要三步：

* 告诉file模块，你要使用jinja
	vim /srv/salt/lamp/config.sls
	apache-config:
	  file.managed:
	    - name: /etc/httpd/conf/httpd.conf
	    - source: salt://lamp/files/httpd.conf
	    - user: root
	    - group: root
	    - mode: 644
	    - template: jinjja
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

*　模板的引用　

<pre>
vim /srv/salt/lamp/files/httpd.conf
Listen {{ PORT }}
</pre>

执行：

	 salt 'linux-node2*' state.sls lamp.init

> 模板里面支持`salt/grains/pillar`进行赋值

<pre>
Listen {{ grains['fqdn_ip4'] }}:{{ PORT }}
Listen {{ grains['ipv4'][1] }}:{{ PORT }}
Listen {{ grains['ipv4'][1][-1] }}:{{ PORT }}

</pre>

##### 取IP
<pre>Listen {{ grains['fqdn_ip4'][0][-1:] }}:{{ PORT }}</pre>
<pre>
grans.item ipv4
grants.items fqdn_ip4
</pre>

##### 取mac(salt远程执行模块)
<pre>{{ salt['netwrok.hw_addr']('eth0') }}

salt '*' network.hw_addr eth0</pre>

##### pillar

<pre>{{ pillar['apache'] }}</pre>

一般用于配置用户名密码的时候


Grinas：Listen {{ grains['fqdn_ip4'][0] }}:{{ PORT }}

salt远程执行模块：{{ salt['netwrok.hw_addr']('eth0') }}

Pillar   {{ pillar['apache'] }}

> 上面是写在模板文件中，还有另外一种方法，写在SLS文件里面


# 生产案例

## 规划
1. 系统初始化
2. 功能模块：设置单独的目录(haproxy/nginx/php/mysql/memcache),做到尽可能的全、独立
3. 业务模块：根据业务类型划分，例如web服务，论坛，bbs

## 执行
### salt环境配置
开发、测试（功能测试环境、性能测试环境）、预生产、生产


#### base 基础环境

* init目录
* 环境初始化
* DNS配置  
* history记录时间  
* 记录命令操作
* 内核参数优化
* 安装YUM仓库
* 安装zabbix-agent

#### 准备
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

#### 环境初始化
##### DNS
<pre>
cd /srv/salt/base
mkdir init
cd init
vim dns.sls 
/etc/resolv.conf:
file.managed:
- source: salt://init/files/resolv.conf
- user: root
- gourp: root
- mode: 644
</pre>
##### History记录时间
<pre>
/etc/profile:
  file.append:
    - text:
      - export HISTTIMEFORMAT="%F %T `whoami`"
</pre>

backup: minion

##### 记录命令操作
<pre>
[root@linux-node1 init]# cat audit.sls 
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

##### 安装YUM仓库
<pre>
[root@linux-node1 init]# cat epel.sls 
yum_repo_release:
  pkg.installed:
    - sources:
      - epel-release: http://mirrors.aliyun.com/epel/epel-release-latest-7.noarch.rpm
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
zabbix_agentd.conf
Include=/etc/zabbix/zabbix_agentd.d/
Server={{ Zabbix_Server }}
</pre>


#### prod 环境

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























## 作业

rsyslog  一个环境里面有一个server端，它跟客户端的配置是不一样的，如果管理配置文件的话，怎么除掉pillar是哪两台的机器

所有的minion中除去pillar中item rsyslog的值是server的minion















##### 架构师必备

网络、系统、数据库、云计算、自动化、架构、开发、安全

