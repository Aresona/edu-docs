#

初次安装PostgreSQL的时候，默认生成一个名为postgres的数据库和一个名为postgres的数据库用户。这里需要注意，还生成了一个名为postgres的linux系统用户。

### 数据库操作

* 创建数据库用户
<pre>create user dbuser with password 'password'; </pre>

* 创建用户数据库，并指定所有者为dbuser

<pre>create database exampledb owner dbuser;</pre>

* 将exampledb数据库的所有权限都赋予dbuser,否则dbuser只能登录控制台，没有任何数据库操作权限

<pre>grant all privileges on database exampledb to dbuser;</pre>

> 当在shell下以同名用户登录数据库的时候是不需要输入密码的。

* 默认登录数据库格式

<pre>psql -U dbuser -d exampledb -h 127.0.0.1 -p 5432</pre>

> 如果这些都是默认的话都可以省略，连同数据库名字

### 控制台操作
<pre>\h：查看SQL命令的解释，比如\h select。
\?：查看psql命令列表。
\l：列出所有数据库。
\c [database_name]：连接其他数据库。
\d：列出当前数据库的所有表格。
\d [table_name]：列出某一张表格的结构。
\du：列出所有用户。
\e：打开文本编辑器。
\conninfo：列出当前数据库和连接的信息。</pre>


[PostgreSQL权限体系](http://mysql.taobao.org/monthly/2016/05/03/)