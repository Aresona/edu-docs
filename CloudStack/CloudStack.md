# CloudStack


修改主机名
<pre>
master1
agent1
vim /etc/hosts
vim /etc/hostname
HOSTNAME=master1
HOSTNAME=agent1
</pre>
安装nfs-utils
<pre>
yum install nfs-utils
</pre>
<pre>
vim /etc/exports
/export/primary *(rw,async,no_root_squash,no_subtree_check)
/export/secondary *(rw,async,no_root_squash,no_subtree_check)
mkdir -p /export/primary
mkdir -p /export/secondary
</pre>
<pre>
[root@agent1 opt]# history |tail -100
   36  yum install wget 
   37  yum install net-tools tree sysstat lrzsz -y
   38  vim /etc/sysconfig/network-scripts/ifcfg-eth0 
   39  init 0
   40  vim /etc/sysconfig/network-scripts/ifcfg-eth0 
   41  /etc/init.d/network restar
   42  /etc/init.d/network restart
   43  ifconfig 
   44  ifconfig -a
   45  > /etc/udev/rules.d/70-persistent-net.rules 
   46  init 0
   47  ifconfig 
   48  vim /etc/sysconfig/network
   49  hostname agent1
   50  reboot
   51  date
   52  mount /dev/sdb /export/primary/
   53  vim /etc/fstab 
   54  umount /export/primary/
   55  mount
   56  mkfs -t xfs /dev/sdb
   57  man mkfs
   58  mkfs -t xfs /dev/sdb
   59  mount
   60  mkfs -t xfs /dev/sdb
   61  vim /etc/fstab 
   62  showmount -e 
   63  mount
   64  df -h
   65  mount
   66  mount -a
   67  mount
   68  lsmod|grep kvm_intel
   69  modprobe kvm
   70  lsmod|grep kvm_intel
   71  modprobe kvm_intel
   72  vim /etc/hosts
   73  hostname agent1
   74  yum install ntp -y
   75  chkconfig ntpd on
   76  wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-6.repo
   77  chkconfig ntpd on
   78  /etc/init.d/ntpd start
   79  wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-6.repo
   80  yum install nfs-utils -y
   81  mkdir -p /export/primary
   82  mkdir /export/secondary
   83  vim /etc/exports 
   84  vim /etc/sysconfig/nfs 
   85  /etc/init.d/rpcbind start
   86  chkconfig rpcbind on
   87  /etc/init.d/nfs start
   88  chkconfig nfs on
   89  mkfs.ext4 /dev/sdb
   90  yum install mysql-server
   91  vim /etc/exports 
   92  /etc/init.d/nfs restart
   93  vim /etc/exports 
   94  /etc/init.d/nfs stop
   95  cd /opt/
   96  ls
   97  cd
   98  ls
   99  mv cloudstack.apt-get.eucentos64.8.zip /opt/
  100  cd /opt/
  101  ls
  102  unzip cloudstack.apt-get.eucentos64.8.zip 
  103  ls
  104  mv cloudstack.apt-get.eucentos64.8/* .
  105  ls
  106  yum localinstall cloudstack-common-4.8.0-1.el6.x86_64.rpm 
  107  yum localinstall cloudstack-management-4.8.0-1.el6.x86_64.rpm 
  108  ls
  109  yum localinstall cloudstack-agent-4.8.0-1.el6.x86_64.rpm 
  110  cd /etc/yum.repos.d/
  111  ls
  112  mv my.repo /tmp/
  113  cd -
  114  yum localinstall cloudstack-agent-4.8.0-1.el6.x86_64.rpm 
  115  init 0
  116  lsmod|grep kvm
  117  cd /ot
  118  cd /opt/
  119  ls
  120  vim /etc/libvirt/qemu.conf 
  121  vim /etc/sysconfig/libvirt
  122  vim /etc/sysconfig/libvirtd
  123  vim /etc/libvirt/libvirtd.conf 
  124  vim /etc/sysconfig/libvirtd 
  125  /etc/init.d/libvirtd status
  126  /etc/init.d/libvirtd restart
  127  vim /etc/sysconfig/libvirtd 
  128  lsmod|grep kvm
  129  service libvirtd restart
  130  df -h
  131  tailf /var/log/cloudstack/agent/agent.log 
  132  history |tail 50
  133  history |tail -50
  134  history |tail -70
  135  history |tail -100
</pre>
<pre>
[root@master1 management]# history 
    1  cd /etc/sysconfig/network-scripts/
    2  ls
    3  vim ifcfg-eth0 
    4  /etc/init.d/NetworkManager stop
    5  /etc/init.d/network restart
    6  ping baidu.com
    7  chkconfig | grep 3:on | grep -Ev "sshd|network|rsyslog|crond|sysstat" | awk '{print $1}' | sed -r 's/(.*)/chkconfig \1 off/g' | bash
    8  chkconfig |grep 3:on
    9  sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config 
   10  mount /dev/sr0 /mnt
   11  ls /mnt/
   12  cd /etc/yum.repos.d/
   13  vim my.repo
   14  vim ~/.vimrc
   15  source ~/.vimrc
   16  iptables -L -n
   17  vim /etc/ssh/sshd_config 
   18  echo "*/5 * * * * /usr/sbin/ntpdate time.nist.gov >/dev/null 2>&1" >>/var/spool/cron/root
   19  crontab -3
   20  crontab -e
   21  ulimit -n 65535
   22  cat >> /etc/rc.local <<EOF
   23  > #-S use the 'soft' resource limit
   24  > #-H use the 'hard' resource limit
   25  > #-n the maximum number of open file descriptors
   26  > ulimit -SHn 65535
   27  > #-s the maximum stack size
   28  > ulimit -s 65535
   29  > EOF
   30  vim /etc/rc.local 
   31  vim /etc/rc.local 
   32  echo '*               -       nofile          65535 ' >>/etc/security/limits.conf 
   33  ls
   34  mv * /tmp/
   35  mv /tmp/my.repo .
   36  yum install wget 
   37  yum install net-tools tree sysstat lrzsz -y
   38  vim /etc/sysconfig/network-scripts/ifcfg-eth0 
   39  init 0
   40  vim /etc/sysconfig/network-scripts/ifcfg-eth0 
   41  /etc/init.d/network restart
   42  crontab -l
   43  /usr/sbin/ntpdate ntp1.aliyun.com >/dev/null 2>&1
   44  date
   45  vim /etc/sysconfig/network
   46  vim /etc/hosts
   47  yum install ntp -y
   48  chkconfig ntpd on
   49  cd /etc/yum.repos.d/
   50  vim cloudstack.repo
   51  yum install nfs-utils -y
   52  wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-6.repo
   53  yum install nfs-utils -y
   54  wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-6.repo
   55  yum install nfs-utils -y
   56  vim /etc/exports 
   57  mkdir -p /export/primary
   58  mkdir /export/secondary
   59  vim /etc/sysconfig/nfs 
   60  /etc/init.d/rpcbind start
   61  chkconfig rpcbind on
   62  /etc/init.d/nfs start
   63  chkconfig nfs on
   64  cd
   65  fdisk -l
   66  mkfs.ext4 /dev/sdb
   67  echo $?
   68  yum install mysql-server -y
   69  vim /etc/fstab 
   70  vim /etc/exports 
   71  /etc/init.d/nfs restart
   72  showmount -e
   73  hostname agent
   74  hostname master1
   75  reboot
   76  mount /dev/sdb /export/secondary/
   77  cd /opt/
   78  ls
   79  rm -f cloudstack.apt-get.eucentos64.8.rar 
   80  unzip cloudstack.apt-get.eucentos64.8.zip 
   81  vim /etc/my.cnf 
   82  df -Th
   83  df -TH
   84  mysqladmin -uroot password 123456
   85  mysql -uroot  -p123456 -e "GRANT ALL PRIVILEGES ON *.* TO root@'%' IDENTIFIED BY '123456'";
   86  cd /opt/
   87  ls
   88  vim /etc/exports 
   89  ls
   90  rpm -ivh cloudstack-common-4.8.0-1.el6.x86_64.rpm 
   91  rpm -ivh cloudstack-management-4.8.0-1.el6.x86_64.rpm 
   92  lsmod|grep kvm
   93  modprobe kvm_intel
   94  mount
   95  yum install mysql-server
   96  vim /etc/my.cnf 
   97  service mysqld on
   98  service mysqld start
   99  chkconfig mysqld on
  100  ls
  101  mv cloudstack.apt-get.eucentos64.8.* /opt/
  102  mv systemvm64template-4.6.0-kvm.qcow2.bz2 /opt/
  103  cd /etc/yum.repos.d/
  104  ls
  105  vim mysql.repo
  106  yum install mysql-connector-python -y
  107  cd /opt/
  108  ls
  109  mv cloudstack.apt-get.eucentos64.8/* .
  110  yum install cloudstack-management -y
  111  ls
  112  yum localinstall cloudstack-management-4.8.0-1.el6.x86_64.rpm 
  113  cd /etc/yum.repos.d/
  114  ls
  115  mv my.repo /tmp/
  116  cd -
  117  yum install cloudstack-management -y
  118  ls
  119  yum localinstall cloudstack-management-4.8.0-1.el6.x86_64.rpm 
  120  cloudstack-setup-databases cloud:123456@localhost --deploy-as=root:123456
  121  lsmod|grep kvm
  122  init 0
  123  cd /etc/cloudstack/management/
  124  ls
  125  sz -y db.properties 
  126  netstat -lntup
  127  cloudstack-setup-management
  128  netstat -lntup
  129  netstat -lntup|grep 8080
  130  /usr/share/cloudstack-common/scripts/storage/secondary/cloud-install-sys-tmplt -m /export/secondary/ -f /opt/systemvm64template-4.6.0-kvm.qcow2.bz2 -h kvm -F
  131  vim /etc/exports 
  132  df -h
  133  cd /var/log/cloudstack/
  134  ls
  135  cd management/
  136  ls
  137  tailf catalina.
  138  tailf catalina.out 
  139  history 
</pre>


阿里钉钉
