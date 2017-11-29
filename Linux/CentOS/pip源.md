# python源

## 下载 `pip` 源的包
<pre>
[root@host71 ~]# pip download pexpect --trusted-host pypi3.internal.pdmi.cn
Collecting pexpect
  Downloading http://pypi3.internal.pdmi.cn/simple/pexpect/pexpect-3.3.tar.gz (132kB)
    100% |████████████████████████████████| 133kB 133.7MB/s 
  Saved ./pexpect-3.3.tar.gz
Successfully downloaded pexpect
You are using pip version 8.1.2, however version 9.0.1 is available.
You should consider upgrading via the 'pip install --upgrade pip' command.
</pre>

## 配置本地私有pip仓库
<pre>
[root@ceph1 ~]# yum install httpd-tools -y
[root@ceph1 ~]# pip install pypiserver
Collecting pypiserver
  Downloading pypiserver-1.2.0-py2.py3-none-any.whl (81kB)
    100% |████████████████████████████████| 81kB 526kB/s 
Installing collected packages: pypiserver
Successfully installed pypiserver-1.2.0
You are using pip version 8.1.2, however version 9.0.1 is available.
You should consider upgrading via the 'pip install --upgrade pip' command.
[root@ceph1 ~]# pip install passlib
Collecting passlib
  Downloading passlib-1.7.1-py2.py3-none-any.whl (498kB)
    100% |████████████████████████████████| 501kB 1.3MB/s 
Installing collected packages: passlib
Successfully installed passlib-1.7.1
You are using pip version 8.1.2, however version 9.0.1 is available.
You should consider upgrading via the 'pip install --upgrade pip' command.
[root@ceph1 ~]# mkdir /var/pypi/packages -p
[root@ceph1 ~]# cat .pypirc 
[distutils]
index-servers =
  local

[local]
repository: http://localhost:8080
username: admin
password: admin
[root@ceph1 ~]# htpasswd -sc htpasswd.txt admin
New password: 
Re-type new password: 
Adding password for user admin
[root@ceph1 ~]# pypi-server -p 8080 -P htpasswd.txt /var/pypi/packages &
[1] 42878
</pre>

## 加入包到本地pip仓库
<pre>
[root@ceph1 ~]# ls /var/pypi/packages/
pexpect-3.3.tar.gz
</pre>
> 这里只需要把包放在该目录下就可以了
## 配置本地 `pip源` 配置文件
<pre>
[root@ceph2 ~]# cat .pip/pip.conf 
[global]
extra-index-url = http://192.168.8.201:8080/simple/

[install]
trusted-host=192.168.8.201
</pre>

[参考信息](https://www.liuliqiang.info/post/build-your-own-pip-source/)