## 前期准备

1. 安装ceph-deploy

<pre>
yum install ceph-deploy      # epel源</pre>
2. ceph节点设置

<pre>
yum install ntp ntpdate ntp-doc     for admin node
yum install openssh-server     for all ceph nodes</pre>
3. 创建一个ceph deploy用户,必须有无密码访问sudo的权限
<pre>
echo "{username} ALL = (root) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/{username}
sudo chmod 0440 /etc/sudoers.d/{username}</pre>
4. 在管理节点生成并分发密钥，尽量不要用root和ceph用户

<pre>
ssh-keygen
ssh-copy-id {username}@node1</pre>
5. 修改ssh客户端配置文件，方便使用ceph-deploy时不用单独指定--username

<pre>
[root@node1 ~]# cat .ssh/config 
Host node1
   Hostname node1
   User root
Host node2
   Hostname node2
   User root
Host node3
   Hostname node3
   User root
</pre>
6. 确保联通性

<pre>
ping `hostname -s`</pre>
7. 打开相应的端口

<pre>
firewall-cmd --zone=public --add-service=ceph-mon --permanent    # 在monitor节点
firewall-cmd --zone=public --add-service=cehp --permanent    # 在osds和MDSs节点
firewall-cmd --reload     # 当设置了--permanent时，可以使用reload使其即时生效，不需要重启</pre>
对于iptables:
<pre>
iptables -A INPUT -i {iface} -p tcp -s {ip-address}/{netmask} --dport 6789 -j ACCEPT(monitor)
6800:7300    用于OSDs节点</pre>
8. 设置TTY

<pre>
/etc/sudoers
Defaults:ceph !requiretty</pre>
9. 安装priorities/preferences

<pre>
yum install yum-plugin-priorities -y</pre>

## 存储集群安装

架构图如下：

![](http://docs.ceph.com/docs/master/_images/ditaa-4064c49b1999d81268f1a06e419171c5e44ab9cc.png)

* 创建一个目录用于保存ceph-deploy生成的配置文件和keyring

<pre>
mkdir my-cluster
cd my-cluster
</pre>
> ceph-deploy生成的所有文件都会放在当前目录下

### 开始
* 回滚

<pre>
ceph-deploy purge {ceph-node} [{ceph-node}]
ceph-deploy purgedata {ceph-node} [{ceph-node}]
ceph-deploy forgetkeys
rm ceph.*</pre>
> 上面这些命令可以回滚到最开始，只要是通过ceph-deploy来部署的

* 创建一个cluster

<pre>
[root@node1 my-cluster]# ceph-deploy new node1
[ceph_deploy.conf][DEBUG ] found configuration file at: /root/.cephdeploy.conf
[ceph_deploy.cli][INFO  ] Invoked (1.5.25): /usr/bin/ceph-deploy new node1
[ceph_deploy.new][DEBUG ] Creating new cluster named ceph
[ceph_deploy.new][INFO  ] making sure passwordless SSH succeeds
[node1][DEBUG ] connected to host: node1 
[node1][DEBUG ] detect platform information from remote host
[node1][DEBUG ] detect machine type
[node1][DEBUG ] find the location of an executable
[node1][INFO  ] Running command: /usr/sbin/ip link show
[node1][INFO  ] Running command: /usr/sbin/ip addr show
[node1][DEBUG ] IP addresses found: ['192.168.56.11']
[ceph_deploy.new][DEBUG ] Resolving host node1
[ceph_deploy.new][DEBUG ] Monitor node1 at 192.168.56.11
[ceph_deploy.new][DEBUG ] Monitor initial members are ['node1']
[ceph_deploy.new][DEBUG ] Monitor addrs are ['192.168.56.11']
[ceph_deploy.new][DEBUG ] Creating a random mon key...
[ceph_deploy.new][DEBUG ] Writing monitor keyring to ceph.mon.keyring...
[ceph_deploy.new][DEBUG ] Writing initial config to ceph.conf...
[root@node1 my-cluster]# ls
ceph.conf  ceph.log  ceph.mon.keyring</pre>
> 这里后面可以接多台机器

> 可通过--ceph-conf --cluseter等参数自定义设置

* 如果有多块网卡，可以直接修改配置文件

<pre>
public network = 10.2.1.0/24
</pre>
* 如果使用ipv6环境部署的话，加入下面字段

<pre>
echo ms bind ipv6 = true >> ceph.conf
</pre>

* 安装 ceph 软件包

<pre>
[root@node1 my-cluster]# ceph-deploy install node1 --no-adjust-repos
</pre>
> 这里安装有两种方式，一种是通过本地的源来安装，也就是上面这一种，另外一种是把远程的源复制到本地，然后通过本地再分发给另外的机器，这种方式下需要在源位置放置一个 [releas.asc文件](https://download.ceph.com/keys/release.asc)，具体操作参考[官网](http://docs.ceph.com/ceph-deploy/docs/install.html)

结果如下：
<pre>
[root@node2 yum.repos.d]# rpm -qa|grep ceph
libcephfs1-10.2.7-0.el7.x86_64
ceph-osd-10.2.7-0.el7.x86_64
ceph-radosgw-10.2.7-0.el7.x86_64
python-cephfs-10.2.7-0.el7.x86_64
ceph-common-10.2.7-0.el7.x86_64
ceph-base-10.2.7-0.el7.x86_64
ceph-mon-10.2.7-0.el7.x86_64
ceph-10.2.7-0.el7.x86_64
ceph-selinux-10.2.7-0.el7.x86_64
ceph-mds-10.2.7-0.el7.x86_64</pre>

* 部署初始化monitor节点并收集keys

<pre>
ceph-deploy mon create-initial
[root@node1 my-cluster]# ls
ceph.bootstrap-mds.keyring  ceph.bootstrap-osd.keyring  ceph.client.admin.keyring  ceph-deploy-ceph.log
ceph.bootstrap-mgr.keyring  ceph.bootstrap-rgw.keyring  ceph.conf                  ceph.mon.keyring
</pre>
> ceph-deploy需要是最新版本，否则不支持centos7.2

* 拷贝配置文件及管理key到任意其他节点

<pre>
ceph-deploy admin node1 node2 node3</pre>

### 部署OSD节点

首先，需要保证机器上有空余的磁盘，这里为每台虚拟机准备了一块20G的空闲硬盘，名字是sdb

* 安装osd

<pre>
ceph-deploy osd create node1:sdb node2:sdb node3:sdb</pre>
</pre>

> 这里的 create 命令相当于 `prepare+activate`

另外比较好用的命令

<pre>
ceph-deploy gatherkeys node1
ceph-deploy disk list node2
ceph-deploy disk zap node2</pre>
### 部署radosgw节点
* 修改ceph-deploy目录下的ceph.conf配置文件

<pre>
[client.rgw.node2]
rgw_frontends = "civetweb port=80"
</pre>
* 部署radosgw

<pre>
ceph-deploy --overwrite-conf rgw create node2</pre>
* 重启服务

如果以后需要修改的端口的话，如下：

<pre>
[root@node2 ceph]# systemctl restart ceph-radosgw@rgw.node2
</pre>
## 扩展
### 扩展monitor节点
* 修改配置文件

<pre>
mon_initial_members = node1,node2,node3
mon_host = 192.168.56.11,192.168.56.12,192.168.56.13
public network = 192.168.56.0/24
cluster network = 192.168.56.0/24
</pre>
> 后两行是必须的，前两行可在完成后再补,如果后面修改的话，可以通过命令 `ceph-deploy admin node1 node2 node3` 来进行同步。


* 增加两个monitor节点

<pre>
ceph-deploy --overwrite-conf mon add node2
ceph-deploy --overwrite-conf mon add node3
</pre>

* 添加monitor节点后，ceph将开始同步monitors,并组成一个quorum,可以通过下列命令查看当前的状态

<pre>
ceph quorum_status --format json-pretty</pre>
</pre>