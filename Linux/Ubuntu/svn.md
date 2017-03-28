# Ubuntu下使用svn

## 客户端使用
* 安装

<pre>
sudo apt-get install subversion-tools -y 
</pre>

* checkout

<pre>
svn checkout  svn://192.168.1.190/yunwei --username user svn
Authentication realm: <svn://192.168.1.190:3690> bcd0797a-2108-4fea-ae93-62d7d178e575
Password for 'user': ******

A    svn/内部资源说明
A    svn/内部资源说明/内部资源说明.pdf
A    svn/中网云设备操作详情
</pre>

* add

<pre>
cd svn
mkdir test
svn add test
</pre>

* commit

<pre>
svn ci test -m "test" 
</pre>

* update

<pre>
svn update
</pre>
### 常用svn命令

<pre>
svn help       查看子命令
svn subcmd -h	查看子命令的用法
svn auth --show-passwords	查看当前验证信息
svn auth --remove		删除匹配的授权认证
</pre>

## 在已有的项目中创建一个子目录

<pre>
mkdir test
cd test
svn checkout --username xxx svn://x.x.x.x/
svn cleanup
svn mkdir new
svn commit -m "create new directory"
</pre>