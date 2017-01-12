## Redis安装及简单配置

### 安装
<pre>
$ wget http://download.redis.io/releases/redis-3.2.6.tar.gz
$ tar xzf redis-3.2.6.tar.gz
$ cd redis-3.2.6
$ make
</pre>

## 配置

`redis.conf`

<pre>
bind 192.168.0.58 127.0.0.1
logfile "/u03/redis/redis/logs/redis.log"
save 60 1
save 30 5
save 10 10
dbfilename dump.rdb
dir ./
requirepass hehe
maxmemory 10gb
appendonly yes
appendfsync everysec
</pre>

### 内核参数修改

`sysctl.conf`
<pre>
net.core.somaxconn = 2048
vm.overcommit_memory = 1
</pre>
<pre>
echo never > /sys/kernel/mm/transparent_hugepage/enabled
echo 'echo never > /sys/kernel/mm/transparent_hugepage/enabled' >> /etc/rc.local
chmod +x /etc/rc.d/rc.local
sysctl -p
</pre>

## 开启关闭服务

<pre>
/u03/redis/redis/src/redis-server /u03/redis/redis/redis.conf
/u03/redis/redis/src/redis-cli -a hehe shutdown
</pre>

## 示例

<pre>
$ src/redis-cli
redis> set foo bar
OK
redis> get foo
"bar"
</pre>



## 说明

redis会在 `src` 目录下生成一个dump.rdb的数据文件