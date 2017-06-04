
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
git clone https://github.com/ceph/ceph-ansible
cd ceph-ansible
ansible --version
vim group_vars/all
ceph_stable_rh_storage: true
ceph_stable_rh_storage_cdn_install: true
fsid: $uuidgen
monitor_interface: bond1.2188
monitor_secret: $shuf monitor_keys_example | head -1
journal_size: 10240
public_network: mon_interface/xx 
radosgw_civetweb_port: 8080





