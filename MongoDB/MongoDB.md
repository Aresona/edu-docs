# Mongodb
mongodb安装包组成:

mongodb-org 是一个metapackage,它会自动安装下面四个包

mongodb-org-server 包含mongod后端程序与相关的配置文件和初始化脚本

mongodb-org-mongos 包含mongos后台程序

mongodb-org-shell 包含mongo shell

mongodb-org-tools 包含mongoimport bsondump,mongodump,mongoexport,mongofiles,mongoperf,mongorestroe,mongostat,mongotop等。

## 安装mongodb 3.4
* 创建yum源 `/etc/yum.repos.d/mongodb-org-3.4.repo`
<pre>
[mongodb-org-3.4]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/$releasever/mongodb-org/3.4/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-3.4.asc
</pre>
* 安装MongoDB包和相关的工具
<pre>
yum install mongodb-org -y
</pre>
## 运行 `MongoDB Community Edition`

*  启动MongoDB


<pre>
systemctl start mongod
systemctl enable mongod
</pre>

*  验证 MongoDB启动成功,查看 `/var/log/mongodb/mongod.log` 文件里面有下面这行内容，默认port是27017

<pre>
[initandlisten] waiting for connections on port <port>
</pre>

* 关闭 Monbodb

<pre>
systemctl stop mongod
</pre>

* 重启Mongodb

<pre>
systemctl restart mongod
</pre>

## 卸载 `MongoDB Communit Edition`
* 关闭MongoDB
<pre>
systemctl stop mongod
</pre>
* 卸载安装包
<pre>
yum erase $(rpm -qa|grep mongodb-org)
</pre>
* 删除数据目录
<pre>
rm -f /var/log/mongodb
rm -f /var/lib/mongo
</pre>

## mongo shell使用
mongo shell是一个访问mongodb的交互式的javascript接口，可以使用它操作数据与可以执行管理命令

* 开始 mongo shell
<pre>
cd mongodb_installation_dir
./bin/mongo
</pre>
可以把该路径加入到环境变量。

> 如果在后面不加入其他参数，mongo将默认连接localhost的27017端口。

* mongo shell使用命令
	* 列出当前使用的数据库
	<pre>
	db
	</pre>
	* 切换数据库
	<pre>
	use database
	</pre>
	* 所有可用的数据库
	<pre>
	dbs
	</pre>
	* 退出shell
	<pre>
	quit()
	</pre>
## 副本集(replica set)
MongoDB中的副本集是一种包含相同数据集的mongod进程。副本集提供冗余和高可用。

### replication

一个副本集只有一个 PRIMARY 节点，其它的节点都被认为是 SECONDARY 。主节点会在 oplog 中记录它对数据集的所有操作，并且只有主节点能接受到写请求，虽然有时从节点也会短暂的认为自已是主。

![](https://docs.mongodb.com/manual/_images/replica-set-read-write-operations-primary.bakedsvg.svg)

从节点会复制主节点的 oplog，并且在本地执行这些操作。如果主不可用，则一个合法的从会发起一个选举来使自己成为主节点。

![](https://docs.mongodb.com/manual/_images/replica-set-primary-with-two-secondaries.bakedsvg.svg)

ARBITER节点不存储数据集,但它可以用少的资源来发挥选举的能力,如果当前节点为偶数时,可以通过添加一个ARBITER节点来生成法定人数.

![](https://docs.mongodb.com/manual/_images/replica-set-primary-with-secondary-and-arbiter.bakedsvg.svg)

> 主从间复制是异步的

### 自动切换
当主与从的交流中断10秒钟以上时，从将变为主。官方推荐最小三个节点，三个副本；最多50个节点，7个选举会员。

### 优先级为0的会员

优先级为0的会员不能变为主，也不能触发选举。其它功能与正常从节点一样。

### 三节点集群搭建

![](https://docs.mongodb.com/manual/_images/replica-set-primary-with-two-secondaries.bakedsvg.svg)

一主两从，从节点都可以变为主。主宕掉后，从变为主，当旧的主修复后，重新加入到新的集群中。

创建一个名字为rs0的副本集

* 启动三个实例

<pre>
mkdir -p /srv/mongodb/rs0-0 /srv/mongodb/rs0-1 /srv/mongodb/rs0-2
</pre>

* 每个节点上启动实例

<pre>
mongod --replSet rs0 --port 27017 --bind_ip localhost,<ip address of mongod host> --dbpath /srv/mongodb/rs0-0 --smallfiles --oplogSize 128
</pre>


* 初始化副本集

<pre>
mongo
rsconf = {
  _id: "rs0",
  members: [
    {
     _id: 0,
     host: "<hostname>:27017"
    },
    {
     _id: 1,
     host: "<hostname>:27017"
    },
    {
     _id: 2,
     host: "<hostname>:27017"
    }
   ]
}
rs.initiate( rsconf )
rs.conf()
rs.status()
</pre>
输出类似下面这样
<pre>
{
   "_id" : "rs0",
   "version" : 1,
   "protocolVersion" : NumberLong(1),
   "members" : [
      {
         "_id" : 0,
         "host" : "<hostname>:27017",
         "arbiterOnly" : false,
         "buildIndexes" : true,
         "hidden" : false,
         "priority" : 1,
         "tags" : {

         },
         "slaveDelay" : NumberLong(0),
         "votes" : 1
      },
      {
         "_id" : 1,
         "host" : "<hostname>:27018",
         "arbiterOnly" : false,
         "buildIndexes" : true,
         "hidden" : false,
         "priority" : 1,
         "tags" : {

         },
         "slaveDelay" : NumberLong(0),
         "votes" : 1
      },
      {
         "_id" : 2,
         "host" : "<hostname>:27019",
         "arbiterOnly" : false,
         "buildIndexes" : true,
         "hidden" : false,
         "priority" : 1,
         "tags" : {

         },
         "slaveDelay" : NumberLong(0),
         "votes" : 1
      }
   ],
   "settings" : {
      "chainingAllowed" : true,
      "heartbeatIntervalMillis" : 2000,
      "heartbeatTimeoutSecs" : 10,
      "electionTimeoutMillis" : 10000,
      "catchUpTimeoutMillis" : -1,
      "getLastErrorModes" : {

      },
      "getLastErrorDefaults" : {
         "w" : 1,
         "wtimeout" : 0
      },
      "replicaSetId" : ObjectId("598f630adc9053c6ee6d5f38")
   }
}
</pre>




### 副本集成员状态

* PRIMARY

PRIMARY状态的成员接受写请求，一个副本集同一时间只能有一个PRIMARY，经过选举后 SECONDARY成员会变成 PRIMARY 成员。

* SECONDARY

SECONDARY成员会复制主的数据，并且可配置接收读请求。

* ARBITER

ARBITER成员不复制数据和接受写请求,它主要用来在选举时打破平局。在任何数据库集中，最多只能配置一个ARBITER

### 成功配置文件
/etc/mongod.conf
<pre>
# mongod.conf

# for documentation of all options, see:
#   http://docs.mongodb.org/manual/reference/configuration-options/

# where to write logging data.
systemLog:
  destination: file
  logAppend: true
  path: /var/log/mongodb/mongod.log

# Where and how to store data.
storage:
  dbPath: /var/lib/mongo
  journal:
    enabled: true
#  engine:
#  mmapv1:
#  wiredTiger:

# how the process runs
processManagement:
  fork: true  # fork and run in background
  pidFilePath: /var/run/mongodb/mongod.pid  # location of pidfile

# network interfaces
net:
  port: 27017
  bindIp: 0.0.0.0  # Listen to local interface only, comment to listen on all interfaces.


#security:
#operationProfiling:

#replication:
replication:
    replSetName: "res0"

#sharding:

## Enterprise-Only Options

#auditLog:

#snmp:
</pre>

初始化集群命令
<pre>
use admin

rsconf = {
  _id: "res0",
  members: [
    {
     _id: 0,
     host: "192.168.245.11:27017"
    },
    {
     _id: 1,
     host: "192.168.245.12:27017"
    },
    {
     _id: 2,
     host: "192.168.245.13:27017"
    }
   ]
}
rs.initiate( rsconf )
rs.status()
rs.conf()
</pre>



