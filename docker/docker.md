# Docker

Docker是Docker.lnc公司开源的一个基于LXC(linux container)技术之上构建的Container容器引擎，源代码托管在Github上，基于Go语言并遵从Apache2.0协议开源。

Docker是通过内核虚拟化技术(namespaces及cgroups等)来提供容器的资源隔离与安全保障等。由于Docker通过操作系统层的虚拟化实现**隔离**，所以Docker容器在运行时，不需要类似虚拟机(VM)额外的操作系统开销，提高资源利用率。

## 环境准备
<pre>
yum install docker -y
[root@localhost ~]# rpm -qa|grep  docker
docker-common-1.10.3-46.el7.centos.10.x86_64
docker-1.10.3-46.el7.centos.10.x86_64
systemctl start docker
docker pull centos
docker pull nginx
[root@localhost ~]# ifconfig 
docker0: flags=4099<UP,BROADCAST,MULTICAST>  mtu 1500
        inet 172.17.0.1  netmask 255.255.0.0  broadcast 0.0.0.0
        ether 02:42:0c:19:55:53  txqueuelen 0  (Ethernet)
        RX packets 0  bytes 0 (0.0 B)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 0  bytes 0 (0.0 B)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
</pre>

## 为什么学习docker?
开源是因为做不下去了

**优势**

* 资源利用率
* 回滚

> 运维痛点和技术储备，而且确实可以解决一些问题

## docker三大理念

构建、运输、运行

有点像JAVA,一次构建，到处运行；只要创建了docker镜像，就可以直接运行起来，它可以做一些整体的交付，而不仅仅是代码（docker1.1及代码1.1）、它是Paas层和Saas层的结合。它可以把运行环境和代码做一个整体的打包.

## docker组成部分
它是一个C/S结构。

## docker组件

* 镜像(Image) **:** 和虚拟机类似，作用一样，组成部分有些区别
* 容器(Container)**：** docker使用容器来运行业务，它是从镜像运行的一个实例，相互之间是隔离的，但没有虚拟机隔离怕彻底。
* 仓库(Repository) **：** 运输的过程中需要存储在一个地方，跟glance类似。有一个dockerHub，也是对外的。它是一个集中式的，而git是分布式的
> docker服务挂掉后容器就都停了，但是libvirtd宕机后,KVM是不会宕的

> ubuntu的内核更新比较快，所以很多流行的软件都会选ubuntu来运行。

## docker与KVM(OpenStack)的对比
1. docker容器里面必须启动一个前台的单进程，这个进程不能挂（可以通过脚本启动多个服务，所以必要条件是前台有一个单进程，docker理念就是一个单进程），如果挂了docker容器就自动退出了。不建议启动SSH,也就是不需要连上去看。连上去一般是当做虚拟机来用的。
2. docker网络连接非常弱；而openstack通过neutron灵活使用
3. docker管理简单，没法管，另外就是在复杂的环境，管理简单就是噩梦。多台管理就不简单了。

> 挂了再启一个，挂了就挂了。如果硬要对这个有要求的话，可能不适合使用docker。

## Docker能干什么 
1. 简化配置（可以把运营环境和代码放在一起，也降低依赖性）
2. 代码流水线管理（开发启容器写，保存镜像，测试pull下来测试，运维pull下来并且run起来，虚拟机也可以实现，但是太大了；能做到一致性）
3. 提高开发效率（入职开发就是配环境，windows下也可以通过虚拟机装docker）
4. 隔离应用（也没什么优势）
5. 整合服务器（跟虚拟机差不多）
6. 调试能力（没优势）
7. 多租户环境（没优势）
8. 快速部署（还好）

**自己的东西**

* 面向产品：产品交付（要将会给用户，通过saltstack交付，最low就是安装文档，后来是saltstack执行；以容器的形式交付；还有就是以虚拟机的形式交付，但是一些会不买机器，所以容器可能更好一些；并且现在很多开源项目就有dockfile，这时调研的时候就会很快。）
* 面向开发：简化环境配置（开发第一天的事）
* 面向测试：多版本测试（测试环境就一个，但是如果有4个测试人员同时使用一个测试环境就会有冲突；或者今天要上1.1的版本，明天要1.2的版本，但今天一定要测试1.2的版本，这时就需要等，或者开多实例。这就是串行，变并行（每个测试来个虚拟机，每个测试有自己的虚拟机）；有docker之后，是即用即删的，填上测试的分支，run起来，然后给他用户名密码，停了后自己删除--rm，如果想让现测一次就再启动一个）
* 面向运维：环境一致性（环境回滚）
* 面向架构（自动化扩容（微服务），当负载不够用的时候多启几个docker来运行起来，用消息队列，直接去注册中心就可以了SOA，不需要记什么配置文件）

> docker的坑也很多，如只能在前台运行一个进程，接下来就是网络和存储，真正能用于生产的解决方案还是比较少。



# Docker快速入门
## 镜像管理
获取镜像
查看镜像
删除镜像
## 容器管理
启动容器 docker run --name -h hostname
停止容器docker stop ID
查看容器docker ps -a -l
进入容器docker exec | docker attach |nsenter
删除容器docker rm 
**搜索镜像**

<pre>
docker images
docker search centos   会去dockerhub上搜索
docker pull centos
docker load --input centos.tar		导入镜像
docker save -o centos.tar centos		导出
docker rmi  镜像ID
docker run centos(镜像名称,如果有任何参数应该写名称前面) /bin/echo 'Hello World'(执行的命令可以有可以没有,如果起来就有一个进程就不用执行这个命令了)（另外docker会自动指定一个名称，所以我们可以自己创建一个，管理可以通过ID和名称）
docker ps -a
docker ps
docker run --name mydocker -t -i (-t是让docker分配一个伪终端tty，-i是打开标准输入,方便执行命令) centos /bin/bash   # 新建一个mydocker的容器，镜像是centos
docker run --name mydocker -t -i centos /bin/bash
进来后主机名变了，虽然看着像虚拟机，但它不是一个虚拟机，可以通过ps -aux来查看。
</pre>
操作
<pre>
[root@b11b843b1237 /]# ps aux
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root         1  0.1  0.0  11776  1868 ?        Ss   03:28   0:00 /bin/bash
root        14  0.0  0.0  47424  1660 ?        R+   03:29   0:00 ps aux
如果这里执行exit,那么这个容器生命周期就完了，也就是容器退出了。容器是为了给这个进程做隔离用的，docker是搞不出windows容器的。

如果执行 `cat /proc/cpuinfo` 看到的是物理机的信息，这个问题可以解决也可以不解决，如果解决要用黑科技来解决。

另外在执行docker run的时候如果没有镜像的话，它会自动pull下来。

如果想启动已经停止的container的话

docker start mydocker

起来后有的东西还是前面一个的东西，并且一般不修改（理念），另外起一个，不可变基础设施（只要改了就有可能出问题）

docker attach mydocker(如果再开一个窗口，操作是同步的，简单来说就是单用户模式)执行exit后它就会退出，不靠谱，所以生产一般不用

yum install util-linux
[root@localhost ~]# docker start mydocker
mydocker
[root@localhost ~]# docker inspect -f "{{ .State.Pid }}" mydocker 
3384
nsenter -t 3384 -m -u -i -n -p
nsenter [options] [program [arguments]]
**If program is not given, then ``${SHELL}'' is run (default: /bin/sh).**
当前docker实现的五种命名空间
[root@b11b843b1237 /]# ps -ef
UID        PID  PPID  C STIME TTY          TIME CMD
root         1     0  0 03:44 ?        00:00:00 /bin/bash
root        14     0  0 03:48 ?        00:00:00 -bash		##使用nsenter进入的时候启动的，所以现在exit的时候还有一个/bin/bash在运行
root        28    14  0 03:49 ?        00:00:00 ps -ef
[root@b11b843b1237 /]# exit
logout
[root@localhost ~]# docker ps
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
b11b843b1237        centos              "/bin/bash"         21 minutes ago      Up 5 minutes                            mydocker
</pre>
进入容器脚本(生产常用)
<pre>
[root@localhost ~]# cat docker_in.sh 
#!/bin/bash

# Use nsenter to access docker

docker_in(){
    NAME_ID=$1
    PID=$(docker inspect -f "{{ .State.Pid }}" $NAME_ID)
    nsenter -t $PID -m -u -i -n -p
}

docker_in $1
chmod +x docker_in.sh
[root@localhost ~]# ./docker_in.sh mydocker
[root@b11b843b1237 /]#
</pre>
不想进容器，但需要它的执行命令
<pre>
docker exec mydocker whoami
docker exec -it mydocker /bin/bash
# 两种最佳实现，但建议用第一种
</pre>
删除容器
<pre>
docker rm mydocker   删除容器
docker rmi centos		删除镜像
docker rm -f mydocker		强制删除
docker run --rm centos /bin/echo "hehe" 容器运行完毕后就被删除了
docker save -o nginx.tar nginx
docker load < nginx.tar
docker run -d nginx 	运行在后台
[root@localhost ~]# docker ps
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS               NAMES
c9af6dbb243b        nginx               "nginx -g 'daemon off"   8 seconds ago       Up 6 seconds        80/tcp, 443/tcp     serene_easley
b11b843b1237        centos              "/bin/bash"              35 minutes ago      Up 19 minutes                           mydocker
docker logs c9af6dbb243b  查看访问日志
</pre>
网络
存储
生产实践
仓库
docker概念
docker使用
****

# Docker网络访问
已经pull了一个nginx镜像，但是它还没IP地址和端口，所以无法访问

## 自带的
默认docker会创建一个桥接的网卡docker0,跟KVM创建的桥接网卡作用和功能都是一样的，它们都是通过桥接
brctl show
默认的访问有两种，一种是随机，一种是指定

### 随机映射
<pre>
docker run -d -P nginx
docker ps
root@localhost ~]# docker run -d -P nginx
b018127b5712fa5cd6072bfc2518590c8ac641d7bc62a56d1b76cd66fa5e6653
[root@localhost ~]# docker ps 
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                                           NAMES
b018127b5712        nginx               "nginx -g 'daemon off"   9 seconds ago       Up 5 seconds        0.0.0.0:10001->80/tcp, 0.0.0.0:10000->443/tcp   tiny_wing
</pre>
<pre>
[root@localhost ~]# iptables -L -n
Chain INPUT (policy ACCEPT)
target     prot opt source               destination         

Chain FORWARD (policy ACCEPT)
target     prot opt source               destination         
DOCKER-ISOLATION  all  --  0.0.0.0/0            0.0.0.0/0           
DOCKER     all  --  0.0.0.0/0            0.0.0.0/0           
ACCEPT     all  --  0.0.0.0/0            0.0.0.0/0            ctstate RELATED,ESTABLISHED
ACCEPT     all  --  0.0.0.0/0            0.0.0.0/0           
ACCEPT     all  --  0.0.0.0/0            0.0.0.0/0           

Chain OUTPUT (policy ACCEPT)
target     prot opt source               destination         

Chain DOCKER (1 references)
target     prot opt source               destination         
ACCEPT     tcp  --  0.0.0.0/0            172.17.0.3           tcp dpt:443
ACCEPT     tcp  --  0.0.0.0/0            172.17.0.3           tcp dpt:80

Chain DOCKER-ISOLATION (1 references)
target     prot opt source               destination         
RETURN     all  --  0.0.0.0/0            0.0.0.0/0           
[root@localhost ~]# iptables -t nat -L -n
Chain PREROUTING (policy ACCEPT)
target     prot opt source               destination         
DOCKER     all  --  0.0.0.0/0            0.0.0.0/0            ADDRTYPE match dst-type LOCAL

Chain INPUT (policy ACCEPT)
target     prot opt source               destination         

Chain OUTPUT (policy ACCEPT)
target     prot opt source               destination         
DOCKER     all  --  0.0.0.0/0           !127.0.0.0/8          ADDRTYPE match dst-type LOCAL

Chain POSTROUTING (policy ACCEPT)
target     prot opt source               destination         
MASQUERADE  all  --  172.17.0.0/16        0.0.0.0/0           
MASQUERADE  tcp  --  172.17.0.3           172.17.0.3           tcp dpt:443
MASQUERADE  tcp  --  172.17.0.3           172.17.0.3           tcp dpt:80

Chain DOCKER (2 references)
target     prot opt source               destination         
RETURN     all  --  0.0.0.0/0            0.0.0.0/0           
DNAT       tcp  --  0.0.0.0/0            0.0.0.0/0            tcp dpt:10000 to:172.17.0.3:443
DNAT       tcp  --  0.0.0.0/0            0.0.0.0/0            tcp dpt:10001 to:172.17.0.3:80
</pre>
<pre>
[root@localhost ~]# ./docker_in.sh b018127b5712
root@b018127b5712:/# ps aux
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root         1  0.2  0.1  31724  3016 ?        Ss   06:48   0:00 nginx: master process nginx -g daemon off;
nginx        6  0.0  0.0  32116  1684 ?        S    06:48   0:00 nginx: worker process
root         7  0.6  0.0  20280  1904 ?        S    06:49   0:00 -bash
root        11  0.0  0.0  17492  1160 ?        R+   06:49   0:00 ps aux

</pre>
> 容器里面的IP地址要经过NAT之后才能访问到容器
<pre>
[root@localhost ~]# docker logs b018127b5712
192.168.56.1 - - [10/Sep/2016:06:52:25 +0000] "GET / HTTP/1.1" 200 612 "-" "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/52.0.2743.116 Safari/537.36" "-"
2016/09/10 06:52:25 [error] 6#6: *1 open() "/usr/share/nginx/html/favicon.ico" failed (2: No such file or directory), client: 192.168.56.1, server: localhost, request: "GET /favicon.ico HTTP/1.1", host: "192.168.56.11:10001", referrer: "http://192.168.56.11:10001/"
192.168.56.1 - - [10/Sep/2016:06:52:25 +0000] "GET /favicon.ico HTTP/1.1" 404 571 "http://192.168.56.11:10001/" "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/52.0.2743.116 Safari/537.36" "-"
</pre>
> 随机映射的好处就是端口不会冲突
### 指定映射
<pre>
-p hostPort:containerPort
-p ip:hostPort:containerPort
-p ip::continerPort
-p hostPort:continerPort:udp
-p 81:80 -p 443:443
</pre>
<pre>
docker run -d -p 443:443 -p 82:80 --name nginxv2 nginx
docker port nginxv2
</pre>
<pre>
docker run -d -p 192.168.56.11:81:80 --name mynginx nginx
[root@localhost ~]# docker ps -l
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                               NAMES
47007c4037aa        nginx               "nginx -g 'daemon off"   9 seconds ago       Up 6 seconds        443/tcp, 192.168.56.11:81->80/tcp   mynginx
</pre>
查看映射
<pre>
[root@localhost ~]# docker port mynginx
80/tcp -> 192.168.56.11:81
</pre>
> 因为这种方式会使用nat，所以还可能会影响一些性能。

## docker数据管理
容器分层的概念，如果想让可写的东西永久生效，就要把它提交成一个镜像，分层有一个特别好的概念，就是如果包含的话它就不会再去下载了。

### 数据卷
<pre>
-v /data
-v src:dst
</pre>
数据卷能绕过ufs，类似于uninx下面的mount,在用的时候需要存储数据的时候就可以把这个目录mount到里面去。但是可能不太好管理，
把需要持久化的东西写到这个卷里面，
<pre>
mkdir /data
docker run -d --name nginx-volume-test1 -v /data nginx
[root@localhost ~]# docker inspect -f {{.Mounts}} nginx-volume-test1
[{18fde2a39a09f345108a6e44ac475e693709be11516df27cddb3d684ca52d355 /var/lib/docker/volumes/18fde2a39a09f345108a6e44ac475e693709be11516df27cddb3d684ca52d355/_data /data local  true }]
[root@localhost ~]# cd /var/lib/docker/volumes/18fde2a39a09f345108a6e44ac475e693709be11516df27cddb3d684ca52d355/_data
[root@localhost _data]# ls
[root@localhost _data]# ls
hehe
</pre>
<pre>
mkdir -p /data/docker-volume-nginx
docker run -d --name nginx-volume-test2 -v /data/docker-volume-nginx/:/data nginx(生产常用，这种写法在dockerfile里面不能用，因为一致性变的差了)
</pre>
> 这是一个最简单的，也是以前很多公司在用的。无所谓好坏，这样容器宕了就宕了。

还有几个选项
<pre>
docker run -d --name nginx-volume-test2 -v /data/docker-volume-nginx/:/data:ro nginx
挂载单个文件进去
docker run --rm -it -v /root/.bash_history:/.bash_histosry nginx /bin/bash
</pre>
### 数据卷容器
数据卷容器是可以让一个容器访问另一个容器的卷，不管这个容器是不是正在运行；如它可以让一份数据在多个容器之间共享。
<pre>
docker run -it --name volume-test3 --volumes-from nginx-volume-test2 centos /bin/bash
ls /data
即使把from后面的容器停止了，也并不会影响它的访问；并且只要有人用这个目录，那么停掉后的那个容器是删除不了的。
</pre>
<pre>
--volumes-from
</pre>
实现nfs数据共享功能
<pre>
mkdir /data/nfs-data
docker run -d --name nfs-test -v /data/nfs-data:/data nginx
docker ps
docker run --rm -it --volumes-from nfs-test centos /bin/bash
cd /data
cd nfs-data
touch heheehhe 
ll
</pre>

# Docker镜像构建
docker的重点，一般上官方提供的基础镜像上来做
##　手动构建
手动的，你懂的
<pre>
docker kill $(docker ps -a -q)
docker rm $(docker ps -a -q)
docker ps -a
</pre>
<pre>
docker run --name mynginx -it centos
rpm -ivh http://mirrors.aliyun.com/epel/epel-release-latest-7.noarch.rpm
yum install nginx -y
yum clean all
vi /etc/nginx/nginx.conf
daemon off;
exit
docker ps -a
docker commit -m "My Nginx" ce6cbd632c3c example/mynginx:v1
[root@localhost ~]# docker images
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
example/mynginx     v1                  67316c4737aa        8 seconds ago       369.8 MB
docker.io/centos    latest              980e0e4c79ec        3 days ago          196.7 MB
docker.io/nginx     latest              4efb2fcdb1ab        2 weeks ago         183.4 MB
docker run --name mynginxv1 -d -p 81:80 example/mynginx:v1 nginx
docker logs mynginxv1
</pre>
> 这样做的话就回到了自动化以前，所以就引出了下面的dockerfile来快速构建docker的镜像
##　Dockerfile
它的格式就是文本格式，这个文件格式里面有一些关键字，现在用dockerfile写一遍刚才做的镜像
<pre>
mkdir /opt/dockerfile/nginx -p
cd /opt/dockerfile/nginx/
vim Dockerfile
[root@localhost nginx]# echo "nginx in docker,hahaha" > index.html
[root@localhost nginx]# cat Dockerfile 
<pre>
# This Dockerfile

# Base image
FROM centos

# Maintainer
MAINTAINER Binbin.Ren binbin.ren@isinonet.com

# Commands
RUN rpm -ivh http://mirrors.aliyun.com/epel/epel-release-latest-7.noarch.rpm
RUN yum install -y nginx && yum clean all
RUN echo "daemon off;" >> /etc/nginx/nginx.conf
ADD index.html /usr/share/nginx/html/index.html
EXPOSE 80
CMD ["nginx"]
docker build -t mynginx:v2 .
</pre>
除了注释的第一行必须是FROM
docker run --rm --name mynginxv2 -p 82:80 mynginx:v2
</pre>
<pre>
WORKDIR   cd的意思（设置当前工作目录）
VOLUME   给它一个存放行李的地方（设置卷，挂载主机目录）
</pre>
[dockerfile命令详解](http://url.cn/2CtxTtW)

# 镜像构建生产规划
架构里面一个概念就是分层设计

* 应用服务层
* 运行环境层
* 系统层

首先要做一个跟项目相关的系统镜像，然后看公司有哪些开发环境，并分别构建，最后按业务（有配置有代码）再做各自的镜像。跟salt相似。因为docker镜像是分层设计的，所有我们这里也分层设计。

1. ssh
2. python

centos-ssh
app


<pre>
cd
mkdir docker
cd docker
mkdir system
mkdir runtime
mkdir app
cd system
mkdir centos ubuntu centos-ssh
cd ../runtime
mkdir php java python
cd ../app
mkdir xxx-api
mkdir xxx-amin
cd ..
cd system/centos
wget http://mirrors.aliyun.com/repo/epel-7.repo
vim Dockerfile
# Docker for Centos

# Base image
FROM centos
# Who
MAINTAINER Binbin.Ren binbin.ren@isinonet.com

# Epel
ADD epel-7.repo /etc/yum.repos.d/

# Base pkg
RUN yum install -y wget mysql-devel supervisor git redis tree net-tools sudo psmisc && yum clean all
docker build -t example/centos:base .
docker images
cd ~/docker/runtime/python
vim Dockerfile
# Docker for Centos

# Base image
FROM example/centos:base
# Maintainer
MAINTAINER Binbin.Ren binbin.ren@isinonet.com

# Python env
RUN yum install -y python-devel python-pip supervisor

# Upgrade pip
RUN pip install --upgrade pip
docker build -t example/python .
mkdir ~/docker/system/centos-ssh
cd ~/docker/system/centos-ssh
vim Dockerfile
# Docker for Centos

# Base image
FROM centos
# Who
MAINTAINER heh

# Epel
ADD epel-7.repo /etc/yum.repos.d/

# Base pkg
RUN yum install -y openssh-clients openssl-devel o
penssh-server wget mysql-devel supervisor git redi
s tree net-tools sudo psmisc && yum clean all

# For SSHD
RUN ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key
RUN ssh-keygen -t ecdsa -f /etc/ssh/ssh_host_ecdsa
_key
RUN echo "root:example" | chpasswd
mv ../centos/epel-7.repo .
docker build -t example/centos-ssh .
cd ../../runtime/
cp -r python python-ssh
cd python-ssh
vim Dockfile
FROM example/centos-ssh
docker build -t example-ssh .
docker images

</pre>
<pre>
搜索docker compose,里面有一个python的小案例
cd ~/docker/app/
mkdir shop-api
cd shop-api
vim app.py

yum install -y python-pip
pip install flask
python app.py
192.168.56.11:5000
vim requirements.txt
flask

cp /etc/supervisord.conf .
vim Dockerfile
# Docker for Centos

# Base image
FROM example/python-ssh
# Maintainer
MAINTAINER Binbin.Ren binbin.ren@isinonet.com

# Python env
RUN useradd -s /sbin/nologin -M www
# ADD file
ADD app.py /opt/app.py
ADD requirements.txt /opt/
ADD supervisord.conf /etc/supervisord.conf
nodaemon=true
ADD app-supervisor.ini /etc/supervisord.d/

# Upgrade pip
RUN /usr/bin/pip2.7 install -r /opt/requirements.txt

# Port
EXPOSE 22 5000

# CMD
CMD ["/usr/bin/supervisord","-c","/etc/supervisord.conf"]


vim app-supervisor.ini
[program:shop-api]
command=/usr/bin/python2.7 /opt/app.py
process_name=%(program_name)s
authostart=true
user=www
stdout_logfile=/tmp/app.log
stderr_logfile=/tmp/app.error

[program:sshd]
command=/usr/sbin/sshd -D
process_name=%(program_name)s
authostart=true

docker build -t example/shop-api .
docker run --name shop-api -d -p 88:5000 -p 8022:22 example/shop-api
docker run --name shop-api-v2 -it -p 88:5000 -p 8022:22 example/shop-api:v2 /bin/bash
supervisord -c /etc/supervisord.conf
docker build -t example/shop-api .
把变动很少的放在最上面，只要前面改了后面就会重要构建一遍。
docker run --name shop-api-v3 -d -p 88:5000 -p 8022:22 example/shop-api
</pre>
几个标准：

<pre>
requirements.txt    	写上依赖的python模块
pip install -r requirements.txt
python-demo.ini			写supervisor的配置
</pre>
<pre>
vim /etc/supervisor.conf
</pre>
supervisor可以让我们启动多个进程（supervisord），它会让进程一直在运行，一旦看见它挂了会马上再起来。


# supervisord
<pre>
yum install supervisor -y
rpm -ql supervisor
/etc/supervisord.conf

</pre>
<pre>
测试
cp app-supervisor.ini /etc/supervisord.d/
supervisorctl restart shop-api
supervisorctl restart sshd
</pre>
两个作用：
管理进程
启动多个进程
然后提交到git上



# 最后的
生产最佳实践是都使用supervisord来启动，

# Docker仓库
docker自己提供了一个仓库docker registry,registry2需要https,然后网上文档都需要自签名弄证书上，申请一个证书:https://buy.wosign.com/free/，跟生产差不多，就是级别不一样
<pre>

</pre>
证书和nginx认证，这样私有仓库就齐活了

Docker Registry Nginx+认证方式+https  生产需要弄
1. 申请免费的SSL证书
2. 部署
3. 设置验证
4. proxy_pass 5000
5. docker run -d -p 5000:5000 --name registry registry:2

这个必须会，registry这个功能太low,推荐生产给力的 `https://github.com/vmware/harbor` 安装文档简单地令人发指。这个也是作业

docker compose是一个可以同时管理多个docker应用的东西，下次讲docker的时候需要有一个hub的私有仓库，可以把docker pull和push
,并且harbor也需要https

zip -r docker.zip docker

vmware不仅仅有harbor,还有vic，它由三个项目组成，这三个项目都是apache开源的，它是为vsphere来做的，但是开源的，还有admiral，它是docker的web管理界面，不过是java写的，但harbor是真的好用。

[mesos](https://www.unixhot.com/article/32)

# 手动容器技术
* 文件系统隔离
* 网络隔离
* 进程间通信隔离
* 用户权限的隔离
* PID隔离
## 命名空间
[命名空间](http://dockone.io/article/76)是一个加强版的 `chroot` ，chroot是将应用隔离到一个虚拟的私有root下，LXC内部依赖linux内核的三种隔离机制(isolation infrastructure):

1. Chroot
2. Cgroups
3. Namespaces

> nsenter可以指定命名空间运行程序，一旦这样运行了，那么这个运行的程序就相当于进入了一个隔离的环境，而在指定的时候可以指定不同的命名空间，如pid、net、uts、user、ipc、mount等。实际上，Linux内核实现namespace的主要目的就是为了实现轻量级虚拟化（容器）服务。在同一个namespace下的进程可以感知彼此的变化，而对外界的进程一无所知。这样就可以让容器中的进程产生错觉，仿佛自己置身于一个独立的系统环境中，以此达到独立和隔离的目的。


## Cgroups
cgroups（Control Groups）是Linux内核提供的一种机制，这种机制可以根据特定的行为，把一系列系统任务及其子任务整合（或分隔）到按资源划分等级的不同组内，从而为系统资源管理提供一个统一的框架。通俗的来说，cgroups可以限制、记录、隔离进程组所使用的物理资源（包括：CPU、memory、IO等），为容器实现虚拟化提供了基本保证，是构建Docker等一系列虚拟化管理工具的基石。本质上来说，cgroups是内核附加在程序上的一系列钩子（hooks），通过程序运行时对资源的调度触发相应的钩子以达到资源追踪和限制的目的。



# [Docker镜像](http://blog.daocloud.io/docker-source-code-analysis-part9/)




















































**python虚拟环境管理不同python虚拟环境**

西坝河  通州北院