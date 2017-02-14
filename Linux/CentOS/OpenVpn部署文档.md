## 准备环境

* 两台虚拟机
* 充当服务端虚拟机需要两块网卡

<pre>
eth0:192.168.56.11
eth1:10.10.10.2)
</pre>
* 后端测试虚拟机一块内网网卡
<pre>
eth0:10.10.10.4)
</pre>

### 实现目标：

物理本机 `192.168.56.1` 运行VPN客户端程序后可以访问后端测试机(`10.10.10.4`)

## 开始部署

### 建立 `openvpn` 软件存放目录

<pre>
mkdir -p /usr/local/openvpn
cd /usr/local/openvpn
</pre>

### 安装 `lzo` 压缩模块

<pre>
tar xf lzo-2.06.tar.gz
cd lzo-2.06/
./configure
make
make install
cd ..
</pre>

### 安装 `OpenVpn` 软件

<pre>
yum install openssl openssl-devel -y
tar xf openvpn-2.0.9.tar.gz
cd openvpn-2.0.9/
./configure --with-lzo-headers=/usr/local/include/ --with-lzo-lib=/usr/local/lib/
make
make install
cd ..
ls /usr/local/sbin/openvpn
</pre>

> 上面的都执行成功说明安装成功

## 配置openvpn server

### 建立 `CA(Certificate Authority)` 证书

* 初始化配置命令

<pre>
cd openvpn-2.0.9/easy-rsa/2.0/
cp vars{,.ori}
</pre>

* 修改 `vars` 文件后五行

<pre>
export KEY_COUNTRY="CN"
export KEY_PROVINCE="BJ"
export KEY_CITY="Beijing"
export KEY_ORG="company"
export KEY_EMAIL="2514826467@qq.com"
</pre>

> 这里配置的目的主要是为了在下面建立证书时，会提示上面配置的内容，这时直接回车就好了，不需要敲字符了。

* 生成CA证书

<pre>
[root@localhost 2.0]# source vars
NOTE: If you run ./clean-all, I will be doing a rm -rf on /usr/local/openvpn/openvpn-2.0.9/easy-rsa/2.0/keys
[root@localhost 2.0]# ./clean-all 
[root@localhost 2.0]# ./build-ca 
Generating a 1024 bit RSA private key
......++++++
....++++++
writing new private key to 'ca.key'
-----
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) [CN]:
State or Province Name (full name) [BJ]:
Locality Name (eg, city) [Beijing]:
Organization Name (eg, company) [company]:
Organizational Unit Name (eg, section) []:company
Common Name (eg, your name or your server's hostname) [company CA]:binbin
Email Address [2514826467@qq.com]:
</pre>

执行完上面命令后会在 `keys` 目录下生成相关的证书文件

<pre>
[root@localhost 2.0]# ll keys/
total 12
-rw-r--r-- 1 root root 1257 Feb 13 16:24 ca.crt
-rw------- 1 root root  916 Feb 13 16:24 ca.key
-rw-r--r-- 1 root root    0 Feb 13 16:22 index.txt
-rw-r--r-- 1 root root    3 Feb 13 16:22 serial
</pre>

下面是这几个文件的官方解释

<pre>
Generated files and corresponding OpenVPN directives:
(Files will be placed in the $KEY_DIR directory, defined in ./vars)
  ca.crt     -> root certificate (--ca)
  ca.key     -> root key, keep secure (not directly used by OpenVPN)
  .crt files -> client/server certificates (--cert)
  .key files -> private keys, keep secure (--key)
  .csr files -> certificate signing request (证书签名请求文件)(not directly used by OpenVPN)
  dh1024.pem or dh2048.pem -> Diffie Hellman parameters (--dh)
</pre>

### 生成需要用到的证书文件 

* 生成服务器端密钥key文件和证书

<pre>
[root@localhost 2.0]# ./build-key-server server
Generating a 1024 bit RSA private key
.........................++++++
.....................++++++
writing new private key to 'server.key'
-----
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) [CN]:
State or Province Name (full name) [BJ]:
Locality Name (eg, city) [Beijing]:
Organization Name (eg, company) [company]:
Organizational Unit Name (eg, section) []:company
Common Name (eg, your name or your server's hostname) [server]:
Email Address [2514826467@qq.com]:

Please enter the following 'extra' attributes
to be sent with your certificate request
A challenge password []:123456
An optional company name []:company
Using configuration from /usr/local/openvpn/openvpn-2.0.9/easy-rsa/2.0/openssl.cnf
Check that the request matches the signature
Signature ok
The Subject's Distinguished Name is as follows
countryName           :PRINTABLE:'CN'
stateOrProvinceName   :PRINTABLE:'BJ'
localityName          :PRINTABLE:'Beijing'
organizationName      :PRINTABLE:'company'
organizationalUnitName:PRINTABLE:'company'
commonName            :PRINTABLE:'server'
emailAddress          :IA5STRING:'2514826467@qq.com'
Certificate is to be certified until Feb 11 08:30:56 2027 GMT (3650 days)
Sign the certificate? [y/n]:y


1 out of 1 certificate requests certified, commit? [y/n]y
Write out database with 1 new entries
Data Base Updated
</pre>

> 上面这一步里面需要输入服务端证书的密码，我随便设置了应该一个，正式环境应该注意

上面这步执行完后的变化为在 `keys` 目录下新增了几个文件

<pre>
[root@localhost keys]# ll -h
total 40K
-rw-r--r-- 1 root root 3.9K Feb 13 16:31 01.pem
-rw-r--r-- 1 root root 1.3K Feb 13 16:24 ca.crt
-rw------- 1 root root  916 Feb 13 16:24 ca.key
-rw-r--r-- 1 root root  112 Feb 13 16:31 index.txt
-rw-r--r-- 1 root root   21 Feb 13 16:31 index.txt.attr
-rw-r--r-- 1 root root    0 Feb 13 16:22 index.txt.old
-rw-r--r-- 1 root root    3 Feb 13 16:31 serial
-rw-r--r-- 1 root root    3 Feb 13 16:22 serial.old
-rw-r--r-- 1 root root 3.9K Feb 13 16:31 server.crt
-rw-r--r-- 1 root root  753 Feb 13 16:30 server.csr
-rw------- 1 root root  916 Feb 13 16:30 server.key
</pre>

* 生成客户端证书和 `key` 文件

需要注意的是，这里生成的key文件就相当于以后要登陆的用户名，生成几个就表示有几个账户；一般情况下，同一时刻，一个证书只能被一个客户端使用；如果希望同一个账户可以被不同的人用,需要另外设置。

<pre>
[root@localhost 2.0]# ./build-key client
Generating a 1024 bit RSA private key
....................................................++++++
...................++++++
writing new private key to 'client.key'
-----
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) [CN]:
State or Province Name (full name) [BJ]:
Locality Name (eg, city) [Beijing]:
Organization Name (eg, company) [company]:
Organizational Unit Name (eg, section) []:company
Common Name (eg, your name or your server's hostname) [client]:
Email Address [2514826467@qq.com]:

Please enter the following 'extra' attributes
to be sent with your certificate request
A challenge password []:
An optional company name []:company
Using configuration from /usr/local/openvpn/openvpn-2.0.9/easy-rsa/2.0/openssl.cnf
Check that the request matches the signature
Signature ok
The Subject's Distinguished Name is as follows
countryName           :PRINTABLE:'CN'
stateOrProvinceName   :PRINTABLE:'BJ'
localityName          :PRINTABLE:'Beijing'
organizationName      :PRINTABLE:'company'
organizationalUnitName:PRINTABLE:'company'
commonName            :PRINTABLE:'client'
emailAddress          :IA5STRING:'2514826467@qq.com'
Certificate is to be certified until Feb 11 08:37:38 2027 GMT (3650 days)
Sign the certificate? [y/n]:y


1 out of 1 certificate requests certified, commit? [y/n]y
Write out database with 1 new entries
Data Base Updated
</pre>

> 上面这个地方输入的密码就是以后使用者连接VPN使用的密码，如果不需要密码的话，这里可以保留为空，我这里就是保留为空

执行后引起的变化

<pre>
[root@localhost 2.0]# ll keys/
total 64
-rw-r--r-- 1 root root 3918 Feb 13 16:31 01.pem
-rw-r--r-- 1 root root 3800 Feb 13 16:37 02.pem
-rw-r--r-- 1 root root 1257 Feb 13 16:24 ca.crt
-rw------- 1 root root  916 Feb 13 16:24 ca.key
-rw-r--r-- 1 root root 3800 Feb 13 16:37 client.crt
-rw-r--r-- 1 root root  720 Feb 13 16:37 client.csr
-rw------- 1 root root  916 Feb 13 16:37 client.key
-rw-r--r-- 1 root root  224 Feb 13 16:37 index.txt
-rw-r--r-- 1 root root   21 Feb 13 16:37 index.txt.attr
-rw-r--r-- 1 root root   21 Feb 13 16:31 index.txt.attr.old
-rw-r--r-- 1 root root  112 Feb 13 16:31 index.txt.old
-rw-r--r-- 1 root root    3 Feb 13 16:37 serial
-rw-r--r-- 1 root root    3 Feb 13 16:31 serial.old
-rw-r--r-- 1 root root 3918 Feb 13 16:31 server.crt
-rw-r--r-- 1 root root  753 Feb 13 16:30 server.csr
-rw------- 1 root root  916 Feb 13 16:30 server.key
</pre>

### 生成 `generate diffie hellman parameters`

Diffie Hellman parameters must be generated for the OpenVPN server

* 生成传输进行密钥交换时用到的交换密钥协议文件

<pre>
[root@localhost 2.0]# ./build-dh
Generating DH parameters, 1024 bit long safe prime, generator 2
This is going to take a long time
..........................+...............................................................................................+.................+....+..........................................+...++*++*++*
</pre>

执行结果

<pre>
[root@localhost 2.0]# ls keys/dh1024.pem 
keys/dh1024.pem
</pre>

## 配置并启动服务端

### 创建配置文件目录并转移相应的KEY到该目录下
<pre>
mkdir /etc/openvpn
cp -ap keys /etc/openvpn/
cp ../../sample-config-files/client.conf /etc/openvpn
cp ../../sample-config-files/server.conf /etc/openvpn/
ls /etc/openvpn/
cd /etc/openvpn/
</pre>

### 修改服务端配置文件 `server.conf`

这里只写修改过的项

<pre>
proto tcp
client-to-client
duplicate-cn
push "route 10.10.10.0 255.255.255.0"
</pre>

> 这里的push后面的网段地址是内网IP地址段


#### 重要参数解释

参数 | 功能
--- | --- |
server 10.8.0.0 255.255.255.0 |VPN SERVER动态分配给VPN CLIENT的地址池，一般不需要更改（SERVER端一般会用10.8.0.1作为它自己的地址，其它的会交给CLIENTS），这个段不要和任何网络地址段重复 
duplicate-cn | 允许多个客户端使用同一个账号连接（生产场景推荐自己有自己的）
keepalive 10 120 | 每10秒ping一次，若是120秒未收到包，就认定客户端断线
comp-lzo | 开启压缩功能，需要同时在客户端配置
persist-key | 当vpn超时后，当重新启动VPN后，保持上一次使用的私钥，而不是重新读取私钥
persist-tun | 通过keepalive检测vpn超时后，当重新启动VPN后，保持tun或者tap设备自动连接状态
status openvpn-status.log | openvpn日志状态信息
verb 3 | 指定日志文件冗余

### 配置系统环境

<pre>
echo 1 > /proc/sys/net/ipv4/ip_forward
</pre>
<pre>
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
sysctl -p
</pre>

### 启动服务

<pre>
/usr/local/sbin/openvpn --config /etc/openvpn/server.conf &
</pre>

## 配置 `openvpn` 客户端配置文件

### 生成客户端配置文件并修改 `client.conf`

<pre>
proto tcp
remote 192.168.56.11 1194
ns-cert-type server
</pre>
<pre>
cp client.conf client.ovpn
</pre>
### 修改完后把下面几个文件拷贝到客户端

* ca.crt
* client.crt
* client.key
* client.ovpn

# 客户端配置

1. windows用户首先下载并安装openvp客户端软件 `openvpn-2.2.2-install.exe`
2. 找到安装目录下的 `config` 目录，并把上面四个文件都拷贝进去
3. **以管理员身份运行**客户端软件并连接
4. 测试连通性

## 相关图示

![](http://i.imgur.com/zJbVY8z.png)

![](http://i.imgur.com/Ytlw5V0.png)