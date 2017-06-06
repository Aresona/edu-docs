
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