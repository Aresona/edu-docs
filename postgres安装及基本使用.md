-# postgres安装

## 通过 `yum` 源安装

<pre>
下面这个repo是官方提供的，是最新的
yum install http://yum.postgresql.org/9.4/redhat/rhel-6-x86_64/pgdg-redhat94-9.4-1.noarch.rpm
</pre>
[可以通过这个网站来下载任意版本的repo文件](http://yum.postgresql.org/repopackages.php)
<pre>
[root@localhost yum.repos.d]# cat pgdg-92-centos.repo 
[pgdg92]
name=PostgreSQL 9.2 $releasever - $basearch
baseurl=http://yum.postgresql.org/9.2/redhat/rhel-$releasever-$basearch
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-PGDG-92

[pgdg92-source]
name=PostgreSQL 9.2 $releasever - $basearch - Source
failovermethod=priority
baseurl=http://yum.postgresql.org/srpms/9.2/redhat/rhel-$releasever-$basearch
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-PGDG-92
yum install postgresql-server -y 
postgresql-setup initdb
systemctl start postgresql.service
systemctl enable postgresql.service

</pre>
主配置文件 `/var/lib/pgsql/data/postgresql.conf`
>  The line in question contains the string
'listen_addresses' -- you need to both uncomment the line and set the value
to '*' to get the postmaster to accept nonlocal connections.  You'll also need
to adjust pg_hba.conf appropriately.


可能的两个帮助文件

* /usr/share/doc/postgresql-9.2.15/README
* /usr/share/doc/postgresql-9.2.15/README.rpm-dist

日志目录

* /var/lib/pgsql/data/pg_log

#### 初始化数据库（可能用了其他命令）
<pre>
service postgresql-9.4 initdb
</pre>
#### 设置环境变量（暂时没做）

<pre>
vim /etc/profile
export PGHOME=/usr/pgsql-9.4
export PGDATA=/var/lig/pgsql/9.4/data
export PATH=$PGHOME/BIN:$PATH 
</pre>
## 通过图形界面安装器安装

[地址](https://www.postgresql.org/download/linux/redhat/)

这个网页的最下面有关于图形化安装的东西(Graphical installer)

下载后直接安装，可以选上postgies的插件

<pre>chmod +x postgresql-9.2.17-1-linux-x64.run</pre>


## PostGres数据库迁移

### 导出数据

<pre>./pg_dump 数据库名 > xxx.bak</pre>


### 导入数据库

<pre>createdb 数据库名
psql 数据库名 < xxx.bak
</pre>

> 这种方法需要已经建立好了对应的用户，并且需要一个库一个库的导入数据，后面也会遇到一些角色不存在，用户不存在，扩展不存在的错误

### stackoverflow总结

[stackoverflow](http://stackoverflow.com/questions/1237725/copying-postgresql-database-to-another-server)

最快最简单的方法（不需要创建中间文件）
<pre>
pg_dump -C -h localhost -U localuser dbname | psql -h remotehost -U remoteuser dbname
或者
pg_dump -C -h remotehost -U remoteuser dbname | psql -h localhost -U localuser dbname
</pre>
如果数据库太大或者网络不好的话可以通过压缩工具来完成
<pre>
pg_dump -C dbname | bzip2 | ssh  remoteuser@remotehost "bunzip2 | psql dbname"
或者
pg_dump -C dbname | ssh -C remoteuser@remotehost "psql dbname"
</pre>

* 讨论一

`pg_basebackup` 对于大数据库来说可能更好一点，但是可能貌似需要两台机器都是同一版本的数据库

* 讨论二

如果在不同版本的数据库间拷贝的话用pg_dumpall可能会好一点

<pre>pg_dumpall -p 5432 -U myuser91 | psql -U myuser94 -d postgres -p 5434</pre>

### DigitalOcean总结

[DigitalOcean](https://www.digitalocean.com/community/tutorials/how-to-back-up-restore-and-migrate-postgresql-databases-with-barman-on-centos-7)

#### PostgreSQL提供了两种备份方式

* 逻辑备份
* 物理备份

##### 逻辑备份
逻辑备份是通过 `pg_dump` 和 `pg_dumpall` 两个PostgreSQL自带的命令来完成的
* 可以备份单个数据库及全部数据库
* 可以只备份结构、只备份数据、只备份单个的表，或者它们全部
* 可以导出数据为纯SQL语句及二进制形式
* 可以被 `pg_restore` 命令恢复
* 不能及时恢复
> 这个意思就是假如你在上午2点备份，那么如果你在10点恢复的时候就会损失8个小时的数据，

##### 物理备份

物理备份跟逻辑备份不一样，因为它们只处理 binary 格式的并且做文件级别的备份

* 提供 `point-in-time` 恢复
* 备份 Postgres `data` 目录和 `WAL（Write Ahead Log）`文件
* 需要耗费大量的磁盘空间
* 使用 `pg_start_backup` 和 `pg_stop_backup` 命令。然而这些命令需要被 scripted,使得物理备份变成一个复杂的过程
* 不能备份单个的数据库及结构。

> WAL文件包含对一个数据库操作的事物（INSERT,UPDATE or DELETE）的列表.包含实际数据的数据库文件位于 `data` 目录，因此当从一个物理备份文件中恢复某一个时间点的数据时，需要首先恢复 `data` 目录，然后再通过WAL文件从上恢复

##### Barman
传统的DBAs会自己写脚本或者定时任务实现物理备份。Barman通过一个标准的方式来完成这个功能

Barman(Backup and Recovery Manager)是一个开源的备份工具，由2ndQuadrant解决方案公司开发，它是用python语言写的。

* 完全免费
* 它是一个维护良好的应用程序，并且可以从供应商的专业支持
* 把DBAs从繁琐的写脚本和测试复杂脚本和定时任务的工作解放出来
* 可以把多个数据库实例备份在同一个中心位置 
* 提供压缩机制和最小化流量和磁盘空间


###### 通过第三方软件Barman模拟备份恢复
这个实验需要三台服务器，一台是主数据库，一台是干净的纯净服务器，当做恢复的服务器，另外一台是安装备份软件的服务器

* 安装PostgreSQL数据库服务器

<pre>
wget http://yum.postgresql.org/9.4/redhat/rhel-7Server-x86_64/pgdg-centos94-9.4-1.noarch.rpm
yum install pgdg-centos94-9.4-1.noarch.rpm -y
yum install postgresql94-server postgresql94-contrib -y
</pre>
> 默认安装完数据库后会在系统中创建一个postgres用户，默认没有密码，我们需要通过sudo切换过去


* 配置PostgreSQL

默认通过YUM安装数据库后，它们的默认数据及配置文件目录是在 `/var/lib/pgsql/9.4/data` 下，二进制程序在 `/usr/pgsql-9.4/bin` 下面，一开始数据库目录是空的，我们需要运行initdb程序初始化数据库集群并且创建必要的文件
<pre>
/usr/pgsql-9.4/bin/postgresql94-setup initdb
</pre>
一旦初始化后就会在data目录生成postgresql.conf配置文件，它是postgresql数据库的主配置文件，我们需要在这个文件里面修改两个配置文件
<pre>
listen_addresses = '*'		## 监听哪个端口
port = 5432
</pre>
修改完上面文件后我们还需要修改一个hba(host based access)配置文件，它指定可以连接到数据库的主机和IP段。如果匹配不上这些规则的请求将被拒绝
<pre>
pg_hba.conf
host        all             all             your_web_server_ip/32          md5
</pre>
> 它表示需要通过密码认证和MD5加密

启动数据库

<pre>
systemctl start postgresql-9.4.service
systemctl enable postgresql-9.4.service
</pre>
可以通过查看日志的后几行查看数据库是否接受请求
<pre>
< 2015-02-26 21:32:24.159 EST >LOG:  database system is ready to accept connections
< 2015-02-26 21:32:24.159 EST >LOG:  autovacuum launcher started
</pre>

* 在主库中创建一些数据及表

<pre>
su - postgres
psql
create database mytestdb;
\connect mytestdb;
create table mytesttable1(id integer NULL);
create table mytesttable2(id integer NULL);
\q
</pre>

* 安装Barman

<pre>
yum install -y epel-release
wget http://yum.postgresql.org/9.4/redhat/rhel-7Server-x86_64/pgdg-centos94-9.4-1.noarch.rpm
rpm -ivh pgdg_centos94-9.4-1.noarch.rpm
yum install barman -y
</pre>
> 通过YUM安装Barman后也会在系统中创建一个barman的用户，同样也没有密码，只能通过sudo用户切换过去

* 创建这几台服务器之间的免密钥登录
<pre>
1. 保证主库及从库上的 postgres 用户可以免密钥登录到备份服务器上
2. 保证备份服务器上的 barman 用户可以免密钥登录到主库及从库上。
</pre>
* 配置 barman 备份

BARMAN的主要配置文件是 `/etc/barman.conf`。这个配置文件包含一个全局([barman])的配置和你想备份的每个服务器的配置。默认该文件包含一个叫做main的简单postgreSQL服务的部分，它默认是没有被注释的。可以把它当做模板来创建你想备份的。

> 在这个文件里面是通过 `;` 来做为注释的；还有一个需要注意的是有一个 `configuration_files_directory` 参数，它默认值是 `/etc/barman.d` ，也就是说默认在这个目录下的以.conf结尾的配置文件也是起作用的。

<pre>
/etc/barman.conf
[barman]
compression = gzip
reuse_backup = link
immediate_checkpoint = true   ## 当做全备时候会发送给数据库一个checkpoint参数，然后数据库会把缓存中的数据写到数据文件中
asebackup_retry_times = 3
basebackup_retry_sleep = 30
last_backup_maximum_age = 1 DAYS
</pre>
> barman在创建全量备份的时候会通过文件级的增量备份来节省空间，对应上面第二个选项

做完上面的操作后我们其实是做了下面几步：
<pre>
1. 保持默认的备份位置
2. 说明备份空间应该被节省，WAL日志将被压缩并且基础备份会使用增量数据备份
3. 如果备份在某些情况下失效的话，barman会重试三次
4. 一天之内必须备份一次
</pre>

*服务器相关设置*
<pre>
[mian-db-server]
description = "Main DB Server"
ssh_command = ssh postgres@main-db-server-ip
conninfo = host=main-db-server-ip user=postgres
retention_policy_mode = auto
retention_policy = RECOVERY WINDOW OF 7 days
wal_retention_policy = main
</pre>
> 在生产环境中7天这个值可以适当的放大一点。

* 配置 `postgresql.conf` 文件

这里做的配置是关于ARVHIVE模式的

<pre>
1. 首先我们需要定位incoming backup directgory的值
<pre>su - barman
barman show-server main-db-server |grep incoming_wals_directory</pre>
2. 切换到主数据库中修改postgresql.conf文件
<pre>
wal_level = archive                     # minimal, archive, hot_standby, or logical
archive_mode = on               # allows archiving to be done
archive_command = 'rsync -a %p barman@barman-backup-server-ip:/var/lib/barman/main-db-server/incoming/%f'                # command to use to archive a logfile segment
# 这里的两个百分号参数都不需要修改
</pre></pre>

> 上面的参数意思是修改 `archive_command` 参数让postreSQL把它的WAL文件发送到备份服务器

* 测试 BARMABN 

<pre>
su - barman
barman check main-db-server
barman list-server
</pre>

* 创建第一个备份

<pre>barman backup main-db-server</pre>

*备份目录*

`/var/lib/barman`

一般每一个备份条目都会创建一个子目录，子目录下面又有三个子目录
<pre>
* base: backup files 存储的地方
* incoming: PostgreSQL发送它的全部WAL文件到这个目录下面
* wals: Barman 复制上一个目录中的内容到这里
</pre>

> 当恢复的时候，Barman会把base中的内容恢复到指定的目录，然后通过wals里面的内容让目录服务器处于一个不断的状态。

*其他使用方法*

<pre>
barman list-backup main-db-server
barman show-backup main-db-server backup-id
barman list-files main-db-server backup-id
</pre>

* 做定时任务备份 

<pre>
crontab -e
30 23 * * * /usr/bin/barman backup main-db-server
* * * * * /usr/bin/barman cron
</pre>

> 第二条命令会在WAL文件和基础备份文件上做一个持续操作

* 模拟“事故”

<pre>
psql
\connect mytestdb;
\dt
drop table mytesttable2;
</pre>

* 恢复或者迁移到一个远程服务器上

在热备服务器上操作
<pre>
systemctl stop postgresql-9.4.service
</pre>
在备份服务器上操作
<pre>
barman show-backup main-db-server latest
</pre>

> 执行这一步的目的就是找出包含自己删除信息的备份文件，并且记录备份ID

恢复

<pre>
barman recover --target-time "Begin time"  --remote-ssh-command "ssh postgres@standby-db-server-ip"   main-db-server   backup-id   /var/lib/pgsql/9.4/data
</pre>
启动数据库并查看结果 
<pre>
systemctl start postgres-9.4.service
</pre>

##### 总结
推荐设计备份的时候使用 `pg_dump` 和 `barman` 配合使用的备份方式，这样的话，如果需要恢复单个数据库的时候就可以通过 `pg_dump` 来完成。或者通过Barman备份方式来进行时间点的备份。

### pg_dump命令重要参数解释
<pre>
-C, --create                 include commands to create database in dump
-F, --format=c|d|t|p         output file format (custom, directory, tar,
                               plain text (default))
</pre>
## 基本使用方法

* 登录数据库

<pre>psql -d postgres -U postgres</pre>
* 列出所有数据库

<pre>\l</pre>

* 列出帮助

<pre>\h</pre>

* 删除数据库

<pre>drop database 数据库名;</pre>

* 为用户设置密码

<pre>\password 用户</pre>

* 创建数据库

<pre>$ createdb xxx</pre>
<pre>=# create database xxx</pre>

* 连接数据库

<pre>
postgres=# \c postgis
You are now connected to database "postgis" as user "postgres".
</pre>

* 创建扩展

<pre>
postgis=# create extension postgis;
CREATE EXTENSION
</pre>

* 列出表

<pre>
postgis=# \dt
 架构模式 |      名称       |  型别  |  拥有者 
 public | spatial_ref_sys | table | postgres
</pre>

* 其他
<pre>postgis=# select count(*) from spatial_ref_sys ;
  3911</pre>
<pre>
postgis=# \dn		# list schemas
 public | postgres
 名称       拥有者
</pre>

* postgres扩展生成目录
<pre>/usr/share/pgsql/extension/</pre>

## PostGIS

PostGIS 则是PostgreSQL的一个扩展，目的是使PostgreSQL支持空间数据的存储和使用，其本质类似于ArcSDE和Oracle Spatial Extension。PostGIS是采用GPL许可发布的，完整地实现了OGC的《Simple Features Specification for SQL》规范，并于2006年获得OGC认证。在此基础上，PostGIS还对规范进行了一些扩展，在后面的特性中我们可以慢慢了解到。

[PostGIS 快速入门](https://live.osgeo.org/zh/quickstart/postgis_quickstart.html)

### 安装

<pre>
yum install postgis -y
</pre>
> 可以通过epel源来安装
### 安装gis扩展

<pre>
psql test -U postgres
create extension postgis;
create extension postgis_topology;
create extension fuzzystrmatch;
CREATE EXTENSION postgis_tiger_geocoder;
</pre>
### 相关参考

[PostgreSQL与PostGIS的关系](http://www.cnblogs.com/cnzzb/archive/2009/04/28/1445237.html)

[Postgresql安装](http://www.centoscn.com/image-text/install/2015/0812/5982.html)

[postgis安装及基本操作](http://www.icanx.cn/p/13)

[postgresql和postgis安装配置](http://my.oschina.net/zxu/blog/371247)

[安装及简单使用postgresql数据库](https://www.digitalocean.com/community/tutorials/how-to-set-up-a-two-node-lepp-stack-on-centos-7)
## 可能会用到的操作
先改为trust,无密码连接进入数据库，修改账户密码

<pre>alter user postgres with password 'foobar';</pre>
再改回 md5 加密认证模式，注意重启配置生效。

[链接](http://www.icanx.cn/p/13)


