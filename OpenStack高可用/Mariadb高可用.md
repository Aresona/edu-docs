# mariadb高可用
## 环境准备
### 节点信息
主机名 | IP |
--- | --
node1 | 192.168.8.146
node2 | 192.168.8.193
node3 | 192.168.8.183
### 主机名解析
<pre>
[root@node3 ~]# cat /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4 node3
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
192.168.8.146	node1
192.168.8.193	node2
192.168.8.183 	node3
</pre>
## 安装相关包
准备 `centos`,`epel`,`openstack`三个源
<pre>
yum install mariadb-galera-server socat python2-PyMySQL MySQL-python percona-xtrabackup -y
</pre>
## 初始化处理
<pre>
systemctl start mariadb
mysql_secure_installation
mysql
grant all privileges on *.* to wsrep@localhost identified by 'mysql';
grant all privileges on *.* to wsrep@127.0.0.1 identified by 'mysql';
grant all privileges on *.* to wsrep@192.168.8.146 identified by 'mysql';
grant all privileges on *.* to wsrep@192.168.8.183 identified by 'mysql';
grant all privileges on *.* to wsrep@192.168.8.193 identified by 'mysql';
systemctl stop mariadb
</pre>

> 权限这一部分只在第一个节点执行，但初始化操作需要在全部节点执行


## 修改配置文件
`/etc/my.cnf.d/server.cnf`
<pre>
[mysqld]
character_set_server=utf8
datadir=/var/lib/mysql
socket=/var/lib/mysql/mysql.sock
user=mysql
binlog_format=ROW
bind-address=192.168.8.146
max_connections=2048
wait_timeout=50
key_buffer_size=800M
expire_logs_days=30

# InnoDB Configuration
default_storage_engine=innodb
innodb_autoinc_lock_mode=2
innodb_flush_log_at_trx_commit=0
innodb_buffer_pool_size=2048M
innodb_file_per_table=1
innodb_flush_method=O_DIRECT
innodb_io_capacity=2000
innodb_log_files_in_group=2
innodb_log_buffer_size=64M
innodb_log_file_size=1024M


# Galera Cluster Configuration
wsrep_debug=1
wsrep_sync_wait=1
wsrep_provider=/usr/lib64/galera/libgalera_smm.so
wsrep_provider_options="pc.recovery=TRUE;gcache.size=300M"
wsrep_cluster_name="mysql_cluster_name"
wsrep_cluster_address="gcomm://192.168.8.146,192.168.8.183,192.168.8.193"
wsrep_sst_auth=wsrep:mysql
wsrep_sst_method=xtrabackup
wsrep_node_address=192.168.8.146
wsrep_node_name=node1
</pre>

> 在三个节点上面同时执行上面步骤，并且此配置文件应该修改相应IP地址和`node_name`

## 启动集群
### 启动第一个节点
<pre>
[root@node1 my.cnf.d]# galera_new_cluster 
</pre>
### 启动其余节点
<pre>
systemctl start mariadb
</pre>
## 集群检测
### 同步检测
* 查看集群节点数(表示正常的)
<pre>
MariaDB [(none)]> show status like 'wsrep_%';
+------------------------------+----------------------------------------------------------+
| Variable_name                | Value                                                    |
+------------------------------+----------------------------------------------------------+
| wsrep_cluster_size           | 3  
| wsrep_local_state_comment    | Synced                                                                                           
| wsrep_ready                  | ON 
1 row in set (0.19 sec)
</pre>

* 节点一上面创建表并插入测试数据

<pre>
CREATE DATABASE galeratest;
USE galeratest;
CREATE TABLE test_table (
        id INT PRIMARY KEY AUTO_INCREMENT,
        msg TEXT ) ENGINE=InnoDB;
INSERT INTO test_table (msg)
        VALUES ("Hello my dear cluster.");
INSERT INTO test_table (msg)
        VALUES ("Hello, again, cluster dear.");
</pre>
* 节点二上查看
<pre>
MariaDB [(none)]> use galeratest;
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Database changed
MariaDB [galeratest]> select * from test_table;
+----+-----------------------------+
| id | msg                         |
+----+-----------------------------+
|  2 | Hello my dear cluster.      |
|  5 | Hello, again, cluster dear. |
+----+-----------------------------+
2 rows in set (0.08 sec)
</pre>

### 脑裂测试

### 故障模拟

## 重启集群

当所有节点都宕掉后，如果想要把集群启动起来，首先需要通过命令 `galera_new_cluster` 来先启动一台，然后再通过正常的 `systemctl` 命令来启动其他的节点

有些情况下我们可能需要重启整个集群，比如断电后，重启整个集群分为下面三个步骤：

1. 定义最高级的节点


# 通过 `HAproxy` 实现 `galera` 的负载均衡

* 安装haproxy

<pre>
yum install haproxy -y
</pre>

* 修改配置文件添加 `galera` 的代理

<pre>
# Stats
listen stats
  mode http
  bind *:10000     
  stats enable     
  stats uri /haproxy
  stats realm HAProxy\ Statistics
  stats auth haproxy:haproxy 

# Load Balancing for Galera Cluster
listen galera 192.168.8.146:3307
     balance source
     mode tcp
     option tcpka
     option mysql-check user haproxy
     server node1 192.168.8.146:3306 check weight 1
     server node2 192.168.8.183:3306 check weight 1
     server node2 192.168.8.193:3306 check weight 1
</pre>
> 上面部分添加到文件 `/etc/haproxy/haproxy.cfg`下


* 开户数据库检查

<pre>
create user 'haproxy'@'192.168.8.146';
</pre>
> 在数据库集群里面创建用户，用于haproxy检测，用户名与上面配置文件里面相同

* 启动haproxy服务

<pre>
systemctl enable haproxy
systemctl start haproxy
</pre>

