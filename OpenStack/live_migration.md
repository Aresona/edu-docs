# openstack配置共享存储下的live_migration
## 配置 `nova-compute`(只需要在计算节点上做就可以了)
`/etc/nova/nova.conf`
<pre>
[libvirt]
images_type=rbd
images_rbd_pool = volumes
images_rbd_ceph_conf = /etc/ceph/ceph.conf
rbd_user = cinder
rbd_secret_uuid = 8acb7fa7-9b3a-4bd7-a36e-583d0def70f4
live_migration_flag="VIR_MIGRATE_UNDEFINE_SOURCE,VIR_MIGRATE_PEER2PEER,VIR_MIGRATE_LIVE,VIR_MIGRATE_PERSIST_DEST,VIR_MIGRATE_TUNNELLED"
live_migration_uri=qemu+tcp://%s/system
virt_type=kvm
</pre>
## 开启 `libvirt`的本地监听
`/etc/libvirt/libvirtd.conf`
<pre>
listen_tls = 0
listen_tcp = 1
auth_tcp = "none"
</pre>
`/etc/sysconfig/libvirtd`
<pre>
LIBVIRTD_ARGS="--listen"
</pre>

<pre>
systemctl restart openstack-nova-compute
systemctl restart libvirtd
</pre>