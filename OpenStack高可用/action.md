* pacemaker+corosync
<pre>
baseurl=http://download.opensuse.org/repositories/nentwork:/ha-clustering:/Stable/CentOS_CentOS-7
yum install lvm2 cifs-utils quota psmisc -y
systemctl enable pcsd
systemctl  enable corosync
systemctl start pcsd
passwd hacluster
vim /etc/corosync/corosync.conf
totem {
	version: 2
	secauth: off
	cluster_name: openstack-cluster
	transport: udpu
}
nolist {
	node {
	ring0_addr: controller1
	nodeid: 1
	}
	node {
	ring0_addr: controller1
	nodeid: 1
	}
	node {
	ring0_addr: controller1
	nodeid: 1
	}
quorum{
	provider: corosync_votequorum
}
logging {
	to_logfile: yes
	logfile: /var/log/cluster/corosync.log
	to_syslog: yes
}
}
ssh-keygen -t rsa
ssh-copyid controller{2,3}
pcs cluster auth controller1 controller2 controller3 -u hacluster -p passw0rd --force
pcs cluster setup --force --name openstack-cluster controller1 controller2 controller3
pcs cluster enable --all
pcs cluster start --all
pcs cluster status
ps -ef|grep pacemaker
corosync-cfgtool -s
corosync -cmapctl|grep members
pcs status corosync
crm_verity -L -V
pfe property set stonith-enabled=false
pcs property set no-quorum-policy=ignore
crm_verity -L -V
</pre>
* haproxy
<pre>
yum install haproxy -y
systemctl enable haproxy
cd /etc/rsyslog.d
vim haproxy.conf
$Modload imudp
$UDPServerRun 514
$template Haproxy,"%msg%n"
local0.=info -/var/log/haproxy.log;Haproxy
local0.notice -/var/log/haproxy-status.log;Haproxy
local0.* ~
systemctl restart rsyslog
vim /etc/haproxy/haproxy.cfg
systemctl enable haproxy
systemctl start haproxy
mysql -uroot -p
grant process on *.* to 'clustercheckuser'@'localhost' identified by 'clustercheckpassword!';
flush privileges;
vim /etc/sysconfig/clustercheck
MYSQL_USERNAME=clustercheckuser
MYSQL_PASSWORD=clustercheckpassword!
MYSQL_HOST=localhost
MYSQL_PORT=3306
scp /etc/sysconfig/clustercheck controller{1,2}
vim /usr/bin/clustercheck
scp /usr/bin/clustercheck controller{1,2}
chmod +x /usr/bin/clustercheck
clustercheck
yum install xinetd -y
mv /etc/xinetd.d/mysqlchk /etc/xinetd.d/mysqlchk.bak
vim /etc/xinetd.d/mysqlchk
service mysqlchk
{
	disable = no
	flags = REUSE
	socket_type = stream
	port = 9200
	wait = no
	user = nobody
	server = /usr/bin/clustercheck
	log_on_failure += USERID
	only_from = 0.0.0.0/0
	per_source = ULIMITED
}
scp /etc/xinetd.d/mysqlchk controller{1,2]
vim /etc/services
mysqlchk 9200/tcp	# mysqlchk
scp /etc/services controller[1,2]
systemctl restart xinetd.service
systemctl enable xinetd.service
echo 'net.ipv4.ip_nonlocal_bind = 1' >> /etc/sysctl.conf
echo 'net.ipv4.ip_forward = 1' > >/etc/sysctl.conf
sysctl -p(三个节点都执行)
systemctl restart haproxy
systemctl status haproxy
</pre>
* keystone
<pre>
mysql -uroot -p
create databasse keystone;
grant al privileges on keystone.* to 'keystone'@'localhost' identified by 'passw0rd';
grant al privileges on keystone.* to 'keystone'@'%' identified by 'passw0rd';
exit
yum install openstack-keystone httpd mod_wsgi python-openstackclient memcached python-memcached openstack-utils -y
systemctl enable memcached
systemctl start memcached
systemctl status memcached
openssl rand -hex 10
ADMIN_TOKEN=
mv /etc/keystone/keystone.conf{,.bak}
vim /etc/keystone/keystone.conf
[default]
verbose
admin_token
bind_host = controller1
public_bind_host = 
admin_bind_host =
[database]
connection = mysql://
[memcache]
servers = controller1:11211,controller2:11211,controller3:11211
[token]
caching = true
provider = keystone.token.providers.uuid.Provider
driver = keystone.token.persistence.backends.memcached.Token
token = keystone.auth.plugins.token.Token
[revoke]
driver=
[catalog]
driver = 
[identity]
driver
chown root.keystone /etc/keystone/keystone.conf
chmod 640 /etc/keystone/keystone.conf
vim /etc/httpd/conf/httpd.conf
ServerName controller1
vim /etc/httpd/conf.d/wsgi-keystone.conf
su -s /bin/sh -c "keystone-manage db_sync" keystone(只执行一次)
crm
configure
primitive vip ocf:heartbeat:IPaddr2 params ip=9.110.187.128 cidr_netmask=24 nic=ens160 op start interval=0s timeout=20s op stop interval=0s timeout=20s op monitor interval=30s meta priority=100
show
exit
y
systemctl enable httpd
systemctl start httpd
systemctl status httpd
keystone-manage bootstrap\
--bootstrap-password passw0rd \
--bootstrap-username admin \
--bootstrap-project-name admin \
--bootstrap-role-name admin \
--bootstrap-service-name keystone \
--bootstrap-region-id RegionOne \
--bootstrap-admin-url http://demo.openstack.com:35357 \
--bootstrap-public-url http://demo.openstack.com:5000 \
--bootstrap-internal-url http://demo.openstack.com:5000 
openstack project list --os-username admin --os-project-name admin ...
vim /root/admin-openrc
export OS_USER_DOMAIN_ID
export OS_PROJECT_DOMAIN_ID
export OS_USERNAME
export OS_PROJECT_NAME
export OS_PASSWORD
export OS_IDENTITY_API_VERSION
export OS_AUTH_URL
openstack endpoint create --region RegionOne identity public http://demo.openstack.com:5000/v3
openstack endpoint create --region RegionOne identity admin http://demo.openstack.com:35357/v3
openstack endpoint create --region RegionOne identity internal http://demo.openstack.com:5000/v3
openstack project create --domain default --description "Service Project" service
....
scp admin-openrc controller{1,2}
scp demo-openrc controller{1,2}

</pre>