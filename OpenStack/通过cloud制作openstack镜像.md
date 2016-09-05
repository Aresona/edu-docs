<pre>
wget http://GenericCloud.raw.tar.gz
curl -o .. https://..
mkdir work
tar xf Cetnso.tar.gz
mv CEntos.raw .
rm -rf /home/
mv Centos.raw work
cd work
ll
file CEnt.raw
fdisk -l CENto .raw
kpartx -a Centos.raw 
loseup -a
dd if=/dev/mapper/loop0p1 of=centos7.xfs.raw bs=1M
file centos7.xfs.raw
kpartx -d Centos.raw
rm -f Centos.raw
mkdir /tmp/mnt
mount centoos7.xfs.raw /tmp/mnt
chroot /tmp/mnt /bin/bash
rpm -ivh epel.rpm
echo nameserver 8.8.8.8 > /etc/resolv.conf
yum install epel.rpm
yum install puppetlabs.rpm
yum install puppet
yum install puppet-agent-3.8.6
yum remove chrony -y
yum install update lsof -y
vim /etc/selinx/config
permissive
exit
cp /tmp/mnt/boot/vmlinuz-3...x86_64 .
cp /tmp/mnt/boot/initramfs-..img .
umount /tmp/mnt
source admin-demo.rc
glance image-create --progress -container-format aki --disk-format aki --visibility public --architecture amd64 --name-237.10.1 --file vmlinuz-3.10.0.1.el7.x86_64
glance image-create --progress -container-format ari --disk-format ari --visibility public --architecture amd64 --name initramfs-1...10.1 --file initramfs-..x86_64.img
glance image-create --progress --kernel-id 第一个ID --ramdisk-id 第二个ID --min-ram 512 --min-disk 9 --disk-format ami --container-format ami --visibility public --architecture amd64 --name "Custom Clean CentOS-7" --file centos7.xfs.raw
mount centos7.xfs.raw /tmp/mnt
chroot /tmp/mnt /bin/bash
yum install httpd php php-ldap php-imap php-mbstring -y
cd /var/www/html
vim index.html
heh
exit
umount /tmp/mnt
glance image-create --progress --kernel-id 第一个ID --ramdisk-id 第二个ID --min-ram 512 --min-disk 9 --disk-format ami --container-format ami --visibility public --architecture amd64 --name "Custom WWW CentOS-7" --file centos7.xfs.raw
glance image-list


</pre>

<pre>
[root@openstack-slave1 work]# file CentOS-7-x86_64-GenericCloud-1511.raw
CentOS-7-x86_64-GenericCloud-1511.raw: x86 boot sector; partition 1: ID=0x83, active, starthead 32, startsector 2048, 16775168 sectors, code offset 0x63
[root@openstack-slave1 work]# losetup -a 
/dev/loop0: [2051]:1098557007 (/server/tools/work/CentOS-7-x86_64-GenericCloud-1511.raw)
[root@openstack-slave1 work]# file centos7.xfs.raw 
centos7.xfs.raw: SGI XFS filesystem data (blksz 4096, inosz 256, v2 dirs)
</pre>