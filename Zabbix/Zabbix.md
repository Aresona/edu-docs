## 安装Zabbix 3.0

<pre>
可以用阿里源
rpm -ivh http://mirrors.aliyun.com/zabbix/zabbix/3.0/rhel/7/x86_64/zabbix-release-3.0-1.el7.noarch.rpm
http://www.aclstack.com/284.html
rpm -ivh http://repo.zabbix.com/zabbix/3.0/rhel/7/x86_64/zabbix-release-3.0-1.el7.noarch.rpm
yum install zabbix-server-mysql zabbix-web-mysql -y
yum install zabbix-agent -y
</pre>

### 安装Mariadb

<pre>
yum install mariadb-server mariadb -y
systemctl start mariadb
mysql
create database zabbix character set utf8 collate utf8_bin;
grant all privileges on zabbix.* to zabbix@localhost identified by 'zabbix';
quit
</pre>

### 创建初始化数据库

<pre>
cd /usr/share/doc/zabbix-server-mysql-3.0.3
zcat create.sql.gz | mysql -uroot zabbix
</pre>

### 开启服务端

##### 修改配置文件 
<pre>
# vi /etc/zabbix/zabbix_server.conf
DBHost=localhost
DBName=zabbix
DBUser=zabbix
DBPassword=zabbix
</pre>

##### 启动zabbix-server进程

<pre>
systemctl start zabbix-server 
</pre>

##### 修改PHP配置文件以配合zabbix前端

<pre>
# vim /etc/httpd/conf.d/zabbix.conf
php_value max_execution_time 300
php_value memory_limit 128M
php_value post_max_size 16M
php_value upload_max_filesize 2M
php_value max_input_time 300
php_value always_populate_raw_post_data -1
php_value date.timezone Asia/Shanghai
</pre>

##### 重启httpd服务

    systemctl restart httpd

> Zabbix frontend is available at http://zabbix-frontend-hostname/zabbix in the browser. Default username/password is Admin/zabbix.

### 访问WEB服务器完成安装

    http://192.168.56.11/zabbix

> 当出现 `Configuration file "/etc/zabbix/web/zabbix.conf.php" created.` 的时候说明安装成功了

> 默认安装完后的用户名是Admin,密码是zabbix；它是一个超级管理员。默认zabbix有两个账户，另外一个是guest,没有登录的用户使用的权限都是guest,并且guest无法访问zabbix的objects.

> zabbix服务默认还支持防暴力破解的功能，五次输入不正确的时候Zabbix接口就会停止30秒

> zabbix里面的访问权限（如对服务器的只读权限）只能赋给用户组，不能赋给单独的用户

########## zabbix日志

    /var/log/zabbix/zabbix_server.log


配置Agent端
被动模式的IP地址

/etc/zabbix/zabbix_agentd.conf
Server=127.0.0.1
主动地址
ServerActive=127.0.0.1
systemctl start zabbix-agent




