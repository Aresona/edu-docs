
<pre>
git clone https://github.com/ceph/ceph-ansible
cd ceph-ansible
# first copy the variable file
cp vagrant_variables.yml.sample vagrant_variables.yml
</pre>

* 修改变量文件

`vagrant_variables.yml`
<pre>
mds_vms: 1
rgw_vms: 1
memory: 1024
</pre>

* since most of the time is spent on bootstrapping the virtual machines and installing packages i'll pause the video after the 'vagrant up'; then I'll resume when the deployment is complete;

<pre>
vagrant up
</pre>

* check a bit the deployment

<pre>
vagrant ssh mon0
sudo -i 
ceph -s
ceph osd tree

</pre>
* check the pool

<pre>
ceph osd dump|grep size
</pre>




<pre>
lsb_release -a
yum install ansible -y
git clone https://github.com/ceph/ceph-ansible
cd ceph-ansible
ansible --version
vim group_vars/all
ceph_stable_rh_storage: true
ceph_stable_rh_storage_cdn_install: true
## ceph configuration
fsid: $uuidgen
monitor_interface: bond1.2188
monitor_secret: $shuf monitor_keys_example | head -1
journal_size: 10240
public_network: mon_interface/xx 
radosgw_civetweb_port: 8080
</pre>
`osds`
<pre>
#crush_location: false
#osd_crush_location: "\"root={{ ceph_crush_root }} rack={{ ceph_crush_rack }} host={{ ansible_hostname }}\""
## ceph options
devices:
    - /dev/sdb
    - ....

journal_collocation: true

</pre>
`/etc/ansible/hosts`
<pre>
cat hosts
[mons]
ceph-eno[1:3]

[osds]
ceph-eno[2:5]

[rgws]
</pre>

<pre>
ansible all -m ping
time ansible-playbook site.yaml
ceph -s
ceph osd tree
ceph osd dump|grep size
rbd ls
rbd create foo -s 10240
rbd info foo
</pre>

<pre>
modprobe rbd
rbd map foo
rbd showmapped
file -s /dev/rbd0
curl 0.0.0.0:8080
vim all
cephx_require_signature: false
ansible-playbook site.yaml
</pre>


* 配置存储网络
* 配置主机名及主机解析
* 配置免密钥登陆
* 安装 `ansible`
* 安装 `ceph`
* 克隆代码仓库
* 配置并执行


<pre>
lsb_release -a
yum install ansible -y
git clone https://github.com/ceph/ceph-ansible
cd ceph-ansible
ansible --version
cp group_vars/all.yml.sample group_vars/all
cp group_vars/osds.yml.sample group_vars/osds
cp site.yml.sample site.yml
</pre>
* edit all and osds
`all`
<pre>
[root@node1 group_vars]# egrep -v '^$|^#' all
---
dummy:
ceph_origin: 'distro'
monitor_interface: ens5
journal_size: 5120
public_network: 192.168.122.0/24
</pre>
`osds`
<pre>
[root@node1 group_vars]# egrep -v '^$|^#' osds
---
dummy:
devices:
  - /dev/sdb
journal_collocation: true
</pre>
`/etc/ansible/hosts`
<pre>
[root@node1 group_vars]# cat /etc/ansible/hosts
[mons]
storage[1:3]

[osds]
storage[1:3]
</pre>
<pre>
cd ceph-ansible
ansible-playbook site.yml
</pre>



# 日志盘与数据盘不是同一块盘

* 配置本地时间同步服务器
* 配置存储网络
* 配置主机名及主机解析
* 配置免密钥登陆
* 安装 `ansible`
* 安装 `ceph`
* 克隆代码仓库
* 配置并执行

<pre>
lsb_release -a
yum install ansible -y
git clone https://github.com/ceph/ceph-ansible
cd ceph-ansible
ansible --version
cp group_vars/all.yml.sample group_vars/all
cp group_vars/osds.yml.sample group_vars/osds
cp site.yml.sample site.yml
</pre>
* edit all and osds
`all`
<pre>
[root@ceph1 group_vars]# egrep -v '^$|^#' all
---
dummy:
ceph_origin: 'distro'
monitor_interface: ens3
journal_size: 10240
public_network: 192.168.8.0/24
radosgw_civetweb_port: 8080
</pre>
`osds`
<pre>
[root@ceph1 group_vars]# egrep -v '^$|^#' osds
---
dummy:
devices:
  - /dev/sdb
raw_multi_journal: true
raw_journal_devices:
  - /dev/sdc
</pre>
`/etc/ansible/hosts`
<pre>
[root@ceph1 group_vars]# cat /etc/ansible/hosts 
[mons]
ceph1
ceph2
ceph3
[osds]
ceph1
ceph2
ceph3
ceph4
ceph5
[rgws]
ceph4
[restapis]
ceph4
</pre>
<pre>
cd ceph-ansible
ansible-playbook site.yml
</pre>
正常结果
<pre>
[root@ceph3 yum.repos.d]# ceph -s
    cluster f5c9c62d-4cf5-4242-aecf-ca66fcb8d404
     health HEALTH_OK
     monmap e1: 3 mons at {ceph1=192.168.8.201:6789/0,ceph2=192.168.8.202:6789/0,ceph3=192.168.8.203:6789/0}
            election epoch 38, quorum 0,1,2 ceph1,ceph2,ceph3
     osdmap e18: 5 osds: 5 up, 5 in
            flags sortbitwise,require_jewel_osds
      pgmap v135: 112 pgs, 7 pools, 1588 bytes data, 171 objects
            176 MB used, 249 GB / 249 GB avail
                 112 active+clean
[root@ceph4 yum.repos.d]# curl 192.168.8.204:8080
&lt;?xml version="1.0" encoding="UTF-8"?>&lt;ListAllMyBucketsResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">&lt;Owner>&lt;ID>anonymous&lt;/ID>&lt;DisplayName>&lt;/DisplayName>&lt;/Owner>&lt;Buckets>&lt;/Buckets>&lt;/ListAllMyBucketsResult>[root@ceph4 yum.repos.d]#
</pre>
# 错误案例
<pre>
[root@ceph3 yum.repos.d]# ceph -s
    cluster f5c9c62d-4cf5-4242-aecf-ca66fcb8d404
     health HEALTH_WARN
            clock skew detected on mon.ceph3
            Monitor clock skew detected 
     monmap e1: 3 mons at {ceph1=192.168.8.201:6789/0,ceph2=192.168.8.202:6789/0,ceph3=192.168.8.203:6789/0}
            election epoch 38, quorum 0,1,2 ceph1,ceph2,ceph3
     osdmap e18: 5 osds: 5 up, 5 in
            flags sortbitwise,require_jewel_osds
      pgmap v114: 112 pgs, 7 pools, 1588 bytes data, 171 objects
            175 MB used, 249 GB / 249 GB avail
                 112 active+clean
</pre>
这个错误是由于时间不同步引起的，因为ceph对时间的要求是毫秒级别的，所以需要配置本地时间服务器
