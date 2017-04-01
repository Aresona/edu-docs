piwik安装部署相关记录

### 安装
<pre>
rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm
./configure --prefix=/usr/local/php --enable-fpm --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --with-mysql-sock --with-gd --with-curl --with-libxml-dir --enable-mbstring --with-zlib --with-openssl
make && make install
cp /usr/local/php7.0.17/php.ini-production /usr/local/php/lib/php.ini
cd /usr/local/php/etc
cp php-fpm.conf.default php-fpm.conf
/usr/local/php/etc/php-fpm.d
cp www.conf.default www.conf
</pre>
并且修改里面的用户名和密码为nginx
<pre>
/usr/local/php/sbin/php-fpm &
netstat -lntup|grep 9000


yum install nginx -y
yum install mariadb mariadb-server -y
yum remove php-gd php-common
yum install gd-devel libxml2 libxml2-devel libcurl libcurl-devel zlib openssl openssl-devel php70w-gd -y

nginx.conf
index    index.php index.html index.htm

        location ~ .*\.(php|php5)?$ {
                fastcgi_index   index.php;
                fastcgi_pass    127.0.0.1:9000;
                include fastcgi.conf;
        }

[root@test html]# cat index.php 
<?php phpinfo();?>

rm -f index.php
unzip piwik.zip
mv piwik/* /usr/share/nginx/html
chown -R nginx.nginx /usr/share/nginx/html/*



my.cnf
collation-server = utf8_general_ci
init-connect = 'SET NAMES utf8'
character-set-server = utf8

mysql_secure_installation

create database pwiki;
grant select,insert,update,delete,create,drop,alter,create temporary tables,lock tables on pwiki.* to 'piwik'@'localhost' identified by '123456';
flush privileges;


gzuncompress 
</pre>