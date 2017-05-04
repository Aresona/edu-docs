# 自动化安装
## 自动化安装介绍

1. 网上上的PXE芯片有512字节，存放了DHCP和TFTP的客户端
2. 启动计算机选择网上启动
3. PXE上的DHCP客户端会向DHCP服务器申请IP地址
4. DHCP服务器分配给它IP地址的同时通过以下字段告诉PXE，TFTP的地址和它要下载的文件(next-server 192.168.0.2/filename "pxelinux.0")
5. pxelinux.0告诉PXE要下载的配置文件是 `pxelinux.cfg` 目录下面的default
6. PXE下载并依据配置文件的内容下载启动必须的文件，并通过 `ks.cfg` 开始系统安装

> 目前几乎所有网卡都有PXE这个芯片。

## 为了实现 `PXE+kickstart` 我们之前做了什么？


* 配置服务，如： DHCP、TFTP、（HTTP、FTP和NFS）
* 在DHCP和TFTP配置文件中填入各个客户端机器的信息
* 创建自动部署文件(比如kickstart)
* 将安装媒介解压缩到HTTP/FTP/DNS存储库中

> 这些是使用kickstart自动化安装需要做的事，下面看一下cobbler是怎么完成的

# Cobbler部署

cobbler不仅可以实现简单和智能，还能进行二次开发

## Cobbler功能

* 使用一个以前定义的模板来配置DHCP服务(如果启用了管理DHCP)
* 将一个存储库(yum或rsync)建立镜像或解压缩一个媒介，以注册一个新操作系统
* 在DHCP配置文件中为需要安装的机器创建一个条目，并使用您指定的参数(IP和MAC地址)
* 在TFTP服务目录下创建适当的PXE文件
* 重新启动DHCP服务以反映更改
* 重新启动机器以开始安装(如果电源管理已启用)

> 存储库就是不同的操作系统，这里可以导入不同的操作系统

## Cobbler相关文件
<pre>
[root@linux-node1 ~]# yum -y install cobbler cobbler-web dhcp tftp-server pykickstart httpd
[root@linux-node1 ~]# rpm -ql cobbler  # 查看安装的文件，下面列出部分。
/etc/cobbler                  # 配置文件目录
/etc/cobbler/settings         # cobbler主配置文件，这个文件是YAML格式，Cobbler是python写的程序。
/etc/cobbler/dhcp.template    # DHCP服务的配置模板
/etc/cobbler/tftpd.template   # tftp服务的配置模板
/etc/cobbler/rsync.template   # rsync服务的配置模板
/etc/cobbler/iso              # iso模板配置文件目录
/etc/cobbler/pxe              # pxe模板文件目录
/etc/cobbler/power            # 电源的配置文件目录
/etc/cobbler/users.conf       # Web服务授权配置文件
/etc/cobbler/users.digest     # 用于web访问的用户名密码配置文件
/etc/cobbler/dnsmasq.template # DNS服务的配置模板
/etc/cobbler/modules.conf     # Cobbler模块配置文件

/var/lib/cobbler              # Cobbler数据目录
/var/lib/cobbler/config       # 配置文件
/var/lib/cobbler/kickstarts   # 默认存放kickstart文件
/var/lib/cobbler/loaders      # 存放的各种引导程序

/var/www/cobbler              # 系统安装镜像目录
/var/www/cobbler/ks_mirror    # 导入的系统镜像列表
/var/www/cobbler/images       # 导入的系统镜像启动文件
/var/www/cobbler/repo_mirror  # yum源存储目录

/var/log/cobbler              # 日志目录
/var/log/cobbler/install.log  # 客户端系统安装日志
/var/log/cobbler/cobbler.log  # cobbler日志
From:  张耀博客http://www.zyops.com/autoinstall-cobbler
</pre>

## cobbler操作
### 启动相关服务
<pre>
systemctl start httpd
systemctl start cobblerd
systemctl start rsyncd
cobbler check
</pre>
<pre>
[root@node1 ~]# cobbler check
The following are potential configuration items that you may want to fix:

1 : The 'server' field in /etc/cobbler/settings must be set to something other than localhost, or kickstarting features will not work.  This should be a resolvable hostname or IP for the boot server as reachable by all machines that will use it.
2 : For PXE to be functional, the 'next_server' field in /etc/cobbler/settings must be set to something other than 127.0.0.1, and should match the IP of the boot server on the PXE network.
3 : change 'disable' to 'no' in /etc/xinetd.d/tftp
4 : some network boot-loaders are missing from /var/lib/cobbler/loaders, you may run 'cobbler get-loaders' to download them, or, if you only want to handle x86/x86_64 netbooting, you may ensure that you have installed a *recent* version of the syslinux package installed and can ignore this message entirely.  Files in this directory, should you want to support all architectures, should include pxelinux.0, menu.c32, elilo.efi, and yaboot. The 'cobbler get-loaders' command is the easiest way to resolve these requirements.
5 : enable and start rsyncd.service with systemctl
6 : debmirror package is not installed, it will be required to manage debian deployments and repositories
7 : The default password used by the sample templates for newly installed machines (default_password_crypted in /etc/cobbler/settings) is still set to 'cobbler' and should be changed, try: "openssl passwd -1 -salt 'random-phrase-here' 'your-password-here'" to generate new one
8 : fencing tools were not found, and are required to use the (optional) power management features. install cman or fence-agents to use them

Restart cobblerd and then run 'cobbler sync' to apply changes.
</pre>

> 在启动服务后，通过 `cobbler check` 验证cobbler被正确配置；

### 修改配置

<pre>
sed -i 's/server: 127.0.0.1/server: 192.168.56.11/' /etc/cobbler/settings
sed -i 's/next_server: 127.0.0.1/next_server: 192.168.56.11/' /etc/cobbler/settings
sed -i '/disable/s#yes#no#' /etc/xinetd.d/tftp
systemctl restart tftp
cobbler get-loaders
pass=$(openssl passwd -1 -salt 'cobler' 'cobler');sed -i "s#default_password_crypted: \"\$1\$mF86/UHC\$WvcIcX2t6crBz2onWxyac.\"#default_password_crypted: \"$pass\"#g" /etc/cobbler/settings
systemctl restart cobblerd
cobbler check
</pre>

> TFTP（Trivial File Transfer Protocol,简单文件传输协议）是TCP/IP协议族中的一个用来在客户机与服务器之间进行简单文件传输的协议，提供不复杂、开销不大的文件传输服务。端口号为69。它基于UDP协议而实现，，它只能从文件服务器上获得或写入文件，不能列出目录，不进行认证；tftp协议通常用于引导无盘工作站，将配置文件下载到网络感知打印机，并启动某些操作系统的安装过程。

#### 配置cobbler管理dhcp

<pre>
sed -i 's/manage_dhcp: 0/manage_dhcp: 1/' /etc/cobbler/settings
vim /etc/cobbler/dhcp.template
subnet 192.168.56.0 netmask 255.255.255.0 {
     option routers             192.168.56.2;
     option domain-name-servers 192.168.56.2;
     option subnet-mask         255.255.255.0;
     range dynamic-bootp        192.168.56.100 192.168.56.254;
     default-lease-time         21600;
     max-lease-time             43200;
     next-server                $next_server;
systemctl restart cobblerd
cobbler sync
</pre>

> 这里主要有两个命令：（cobbler check和cobbler sync）
> 
> cobbler check	用来检测使用cobbler还需要解决的问题
> 
> cobbler sync	修改完一些配置的时候把这些相关的信息生成需要的文件


### 导入镜像
<pre>
mount /dev/cdrom /mnt
cobbler import --path=/mnt/ --name=CentOS-7-x86_64 --arch=x86_64
cobbler import --path=/mnt/ --name=CentOS-6-x86_64 --arch=x86_64
</pre>
<pre>
[root@node1 ks_mirror]# cobbler import --path=/mnt/ --name=CentOS-7-x86_64 --arch=x86_64
task started: 2017-05-03_045519_import
task started (id=Media import, time=Wed May  3 04:55:19 2017)
Found a candidate signature: breed=redhat, version=rhel6
Found a candidate signature: breed=redhat, version=rhel7
Found a matching signature: breed=redhat, version=rhel7
Adding distros from path /var/www/cobbler/ks_mirror/CentOS-7-x86_64:
creating new distro: CentOS-7-x86_64
trying symlink: /var/www/cobbler/ks_mirror/CentOS-7-x86_64 -> /var/www/cobbler/links/CentOS-7-x86_64
creating new profile: CentOS-7-x86_64
associating repos
checking for rsync repo(s)
checking for rhn repo(s)
checking for yum repo(s)
starting descent into /var/www/cobbler/ks_mirror/CentOS-7-x86_64 for CentOS-7-x86_64
processing repo at : /var/www/cobbler/ks_mirror/CentOS-7-x86_64
need to process repo/comps: /var/www/cobbler/ks_mirror/CentOS-7-x86_64
looking for /var/www/cobbler/ks_mirror/CentOS-7-x86_64/repodata/*comps*.xml
Keeping repodata as-is :/var/www/cobbler/ks_mirror/CentOS-7-x86_64/repodata
*** TASK COMPLETE ***
</pre>
执行后的效果如下
<pre>
[root@node1 ks_mirror]# ls
CentOS-7-x86_64  config
[root@node1 ks_mirror]# pwd
/var/www/cobbler/ks_mirror
[root@node1 ks_mirror]# ls CentOS-7-x86_64/
CentOS_BuildTag  EULA  images    LiveOS    repodata              RPM-GPG-KEY-CentOS-Testing-7
EFI              GPL   isolinux  Packages  RPM-GPG-KEY-CentOS-7  TRANS.TBL

[root@node1 ks_mirror]# ls config/
CentOS-7-x86_64.repo
[root@node1 ks_mirror]# cat config/CentOS-7-x86_64.repo 
[core-0]
name=core-0
baseurl=http://@@http_server@@/cobbler/ks_mirror/CentOS-7-x86_64
enabled=1
gpgcheck=0
priority=$yum_distro_priority
</pre>
cobbler镜像相关命令
<pre>
cobbler profile list
cobbler profile report
</pre>
默认情况下会指定一个 `ks.cfg` 文件，我们要修改或者自己上传

<pre>
Kickstart                      : /var/lib/cobbler/kickstarts/sample_end.ks
</pre>
<pre>
cobbler profile edit --name=CentOS-7-x86_64 --kickstart=/var/lib/cobbler/kickstarts/CentOS-7-x86_64.cfg
cobbler profile edit --name=CentOS-7-x86_64 --kopts='net.ifnames=0 biosdevname=0'
cobbler sync 
</pre>

#### CentOS6/7下的ks.cfg文件分析
CentOS-7-x86_64.cfg
<pre>
[root@node1 kickstarts]# cat CentOS-7-x86_64.cfg 
#Kickstart Configurator for cobbler by Ares
#platform=x86, AMD64, or Intel EM64T
#System  language
lang en_US
#System keyboard
keyboard us
#Sytem timezone
timezone Asia/Shanghai
#Root password
rootpw --iscrypted $default_password_crypted
#Use text mode install
text
#Install OS instead of upgrade
install
#Use NFS installation Media
url --url=$tree
#System bootloader configuration
bootloader --location=mbr
#Clear the Master Boot Record
zerombr
#Partition clearing information
clearpart --all --initlabel 
#Disk partitioning information
part /boot --fstype="xfs" --ondisk=sda --size=500
part swap --size 16384 --ondisk sda
part / --fstype="xfs" --size 1 --grow --ondisk sda
#System authorization infomation
auth  --useshadow  --enablemd5 
#Network information
$SNIPPET('network_config')
#network --bootproto=dhcp --device=em1 --onboot=on
# Reboot after installation
reboot
#Firewall configuration
firewall --disabled 
#SELinux configuration
selinux --disabled
#Do not configure XWindows
skipx
# System Services
services --enabled="sshd,rsyslog,crond,network"
# Yum repo


#Package install information
%pre
$SNIPPET('log_ks_pre')
$SNIPPET('kickstart_start')
$SNIPPET('pre_install_network_config')
# Enable installation monitoring
$SNIPPET('pre_anamon')
%end

%packages
@^minimal
@compat-libraries
@base
@core
@debugging
@development
sysstat
iptraf
ntp
lrzsz
ncurses-devel
openssl-devel
zlib-devel
OpenIPMI-tools
nmap
screen
%end

%addon com_redhat_kdump --disable --reserve-mb='auto'
%end

%post
echo '00 00 * * * /bin/find /tmp -mtime +7 |xargs rm -rf &> /dev/null' >> /var/spool/cron/root
echo '*/5 * * * * /usr/sbin/ntpdate ntp1.aliyun.com &> /dev/null' >> /var/spool/cron/root
echo '*               -       nofile          65535 ' >>/etc/security/limits.conf
> /etc/issue
> /etc/issue.net
cat >> /etc/sysctl.conf <<EOF
net.ipv4.tcp_fin_timeout = 2
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_keepalive_time = 600
net.ipv4.ip_local_port_range = 10000    65000
net.ipv4.tcp_max_syn_backlog = 16384
net.ipv4.tcp_max_tw_buckets = 36000
net.ipv4.route.gc_timeout = 100
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_synack_retries = 1
net.core.somaxconn = 16384
net.core.netdev_max_backlog = 16384
net.ipv4.tcp_max_orphans = 16384
EOF
sysctl -p
systemctl set-default multi-user.target
systemctl list-unit-files |grep enabled|grep -Ev 'rsyslog|sshd|crond|sysstat|multi-user|default.target|iptables'|awk '{print "systemctl disable "$1}'|bash
chkconfig 2>/dev/null|grep 3:on|grep -v network|awk '{print "chkconfig "$1" off"}'|bash
sed -i 's/#UseDNS yes/UseDNS no/' /etc/ssh/sshd_config
sed -i 's/GSSAPIAuthentication yes/GSSAPIAuthentication no/' /etc/ssh/sshd_config
systemctl restart sshd
# End of the %post section
%end

%post
$yum_config_stanza
%end

%addon com_redhat_kdump --disable --reserve-mb='auto'
%end
</pre>
CentOS-6-x86_64.cfg
<pre>
[root@node1 ~]# cat CentOS-6-x86_64.cfg 
#Kickstart Configurator for cobbler by Ares
#platform=x86, AMD64, or Intel EM64T
key --skip
#System  language
lang en_US
#System keyboard
keyboard us
#Sytem timezone
timezone Asia/Shanghai
#Root password
rootpw --iscrypted $default_password_crypted
#Use text mode install
text
#Install OS instead of upgrade
install
#Use NFS installation Media
url --url=$tree
#System bootloader configuration
bootloader --location=mbr
#Clear the Master Boot Record
zerombr yes
#Partition clearing information
clearpart --all --initlabel 
#Disk partitioning information
part /boot --fstype ext4 --size 1024 --ondisk sda
part swap --size 16384 --ondisk sda
part / --fstype ext4 --size 1 --grow --ondisk sda
#System authorization infomation
auth  --useshadow  --enablemd5 
#Network information
$SNIPPET('network_config')
#network --bootproto=dhcp --device=em1 --onboot=on
#Reboot after installation
reboot
#Firewall configuration
firewall --disabled 
#SELinux configuration
selinux --disabled
#Do not configure XWindows
skipx
#Package install information
%packages
@ base
@ chinese-support
@ core
sysstat
iptraf
ntp
e2fsprogs-devel
keyutils-libs-devel
krb5-devel
libselinux-devel
libsepol-devel
lrzsz
ncurses-devel
openssl-devel
zlib-devel
OpenIPMI-tools
mysql
lockdev
minicom
nmap

%post
#/bin/sed -i 's/#Protocol 2,1/Protocol 2/' /etc/ssh/sshd_config
/bin/sed  -i 's/^ca::ctrlaltdel:/#ca::ctrlaltdel:/' /etc/inittab
/sbin/chkconfig --level 3 diskdump off
/sbin/chkconfig --level 3 dc_server off
/sbin/chkconfig --level 3 nscd off
/sbin/chkconfig --level 3 netfs off
/sbin/chkconfig --level 3 psacct off
/sbin/chkconfig --level 3 mdmpd off
/sbin/chkconfig --level 3 netdump off
/sbin/chkconfig --level 3 readahead off
/sbin/chkconfig --level 3 wpa_supplicant off
/sbin/chkconfig --level 3 mdmonitor off
/sbin/chkconfig --level 3 microcode_ctl off
/sbin/chkconfig --level 3 xfs off
/sbin/chkconfig --level 3 lvm2-monitor off
/sbin/chkconfig --level 3 iptables off
/sbin/chkconfig --level 3 nfs off
/sbin/chkconfig --level 3 ipmi off
/sbin/chkconfig --level 3 autofs off
/sbin/chkconfig --level 3 iiim off
/sbin/chkconfig --level 3 cups off
/sbin/chkconfig --level 3 openibd off
/sbin/chkconfig --level 3 saslauthd off
/sbin/chkconfig --level 3 ypbind off
/sbin/chkconfig --level 3 auditd off
/sbin/chkconfig --level 3 rdisc off
/sbin/chkconfig --level 3 tog-pegasus off
/sbin/chkconfig --level 3 rpcgssd off
/sbin/chkconfig --level 3 kudzu off
/sbin/chkconfig --level 3 gpm off
/sbin/chkconfig --level 3 arptables_jf off
/sbin/chkconfig --level 3 dc_client off
/sbin/chkconfig --level 3 lm_sensors off
/sbin/chkconfig --level 3 apmd off
/sbin/chkconfig --level 3 sysstat off
/sbin/chkconfig --level 3 cpuspeed off
/sbin/chkconfig --level 3 rpcidmapd off
/sbin/chkconfig --level 3 rawdevices off
/sbin/chkconfig --level 3 rhnsd off
/sbin/chkconfig --level 3 nfslock off
/sbin/chkconfig --level 3 winbind off
/sbin/chkconfig --level 3 bluetooth off
/sbin/chkconfig --level 3 isdn off
/sbin/chkconfig --level 3 portmap off
/sbin/chkconfig --level 3 anacron off
/sbin/chkconfig --level 3 irda off
/sbin/chkconfig --level 3 NetworkManager off
/sbin/chkconfig --level 3 acpid off
/sbin/chkconfig --level 3 pcmcia off
/sbin/chkconfig --level 3 atd off
/sbin/chkconfig --level 3 sendmail off
/sbin/chkconfig --level 3 haldaemon off
/sbin/chkconfig --level 3 smartd off
/sbin/chkconfig --level 3 xinetd off
/sbin/chkconfig --level 3 netplugd off
/sbin/chkconfig --level 3 readahead_early off
/sbin/chkconfig --level 3 xinetd off
/sbin/chkconfig --level 3 ntpd on
/sbin/chkconfig --level 3 avahi-daemon off
/sbin/chkconfig --level 3 ip6tables off
/sbin/chkconfig --level 3 restorecond off
/sbin/chkconfig --level 3 postfix off
</pre>

### 存储库

定义一个YUM的镜像，cobbler帮忙管理

#### 构建私有YUM仓库
<pre>
[root@node1 kickstarts]# cobbler repo add --name=newton --mirror=http://mirrors.163.com/centos/7.3.1611/cloud/x86_64/openstack-newton/ --arch=x86_64 --breed=yum
[root@node1 kickstarts]# cobbler reposync
</pre>
它会把网上的源下载到本地，并且自动生成repo文件
#### 添加到profile里面
<pre>
cobbler profile edit --name=CentOS-7-x86_64 --repos="newton" --distro=CentOS-7-x86_64 kickstart=/var/lib/cobbler/kickstarts/CentOS-7-x86_64.cfg
</pre>
要想让新安装的系统也有这个YUM源，需要在 `ks.cfg` 里面加入下面语句

<pre>
%post
$yum_config_stanza
%end
</pre>

### 定制system
<pre>
cobbler system add --name=linux-node1.example.com --mac=00:50:56:35:9C:3B --profile=CentOS-7-x86_64 --ip-address=192.168.56.102 --subnet=255.255.255.0 --gateway=192.168.56.2 --interface=eth0 --static=1 --hostname=linux-node1.example.com --name-servers="192.168.56.2" --kickstart=/var/lib/cobbler/kickstarts/CentOS-7-x86_64.cfg
</pre>

### 自动化重装系统
<pre>
yum install -y koan
[root@linux-node1 conf.d]# koan --server=192.168.56.11 --list=profiles
- looking for Cobbler at http://192.168.56.11:80/cobbler_api
CentOS-7-x86_64
CentOS-6-x86_64
</pre>
列出能重装的系统
<pre>
koan --replace-self --server=192.168.56.11 --profile=CentOS-6-x86_64
</pre>

> 另外，错误装机可以通过环境设计来杜绝，比如设计一个单独的装机VLAN，把要装的机器先放到装机VLAN中，装完后再把它划入到正常的VLAN。


# 深入理解cobbler

![](https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1493874811169&di=5ab968ef6c93842a67920fe214f1c326&imgtype=0&src=http%3A%2F%2Fsunjiangang.blog.chinaunix.net%2Fattachment%2F201606%2F1%2F30212356_1464776865SB4t.png)

## 概念

### Respository
它是通过cobbler把远程yum仓库里面的内容下载到本地，然后自己重新建立一个仓库，供安装完新系统的机器使用，可用于建立自己私有的仓库；

加入定时任务同步公共源
<pre>
cobbler repo add --name=newton --mirror=http://mirrors.163.com/centos/7.3.1611/cloud/x86_64/openstack-newton/ --arch=x86_64 --breed=yum
cobbler reposync
</pre>
<pre>
echo "1 3 * * * /usr/bin/cobbler reposync --tries=3 --no-fail" >> /var/spool/cron/root
</pre>
### image

### Distribution(发行版)
`Distro`是用来安装操作系统的，类似于我们一般使用的ISO文件，通过 `cobbler import` 命令来生成，需要指定
`file path` ；
<pre>
cobbler import --path=/mnt/ --name=CentOS-7-x86_64 --arch=x86_64
</pre>
会自动生成一个 `distro` 和一个 `profile`
<pre>
[root@node1 kickstarts]# cobbler distro report
Name                           : CentOS-7-x86_64
Architecture                   : x86_64
TFTP Boot Files                : {}
Breed                          : redhat
Comment                        : 
Fetchable Files                : {}
Initrd                         : /var/www/cobbler/ks_mirror/CentOS-7-x86_64/images/pxeboot/initrd.img
Kernel                         : /var/www/cobbler/ks_mirror/CentOS-7-x86_64/images/pxeboot/vmlinuz
Kernel Options                 : {}
Kernel Options (Post Install)  : {}
Kickstart Metadata             : {'tree': 'http://@@http_server@@/cblr/links/CentOS-7-x86_64'}
Management Classes             : []
OS Version                     : rhel7
Owners                         : ['admin']
Red Hat Management Key         : <<inherit>>
Red Hat Management Server      : <<inherit>>
Template Files                 : {}
</pre>
### Profile
Profile类似于一个 配置文件，类似于你的 bash_profile， 里面包含你可以添加 kernel 参数，对应的kickstart 文件 以及 此profile 对应的 distro 等等.
<pre>
cobbler profile add --name=centos6.4 --distro=CentOS6.4-x86_64 --kickstart=/var/lib/cobbler/kickstarts/CentOS_6.4.ks 
</pre>
默认导入镜像的时候就会自动创建一个profile,后面可以通过 `cobbler profile edit`来修改里面的内容；也可以像上面这样自己单独创建一个profile，可以指定不同的kickstarts文件来实现不同的安装方式；
<pre>
[root@node1 kickstarts]# cobbler profile report
Name                           : CentOS-7-x86_64
TFTP Boot Files                : {}
Comment                        : 
DHCP Tag                       : default
Distribution                   : CentOS-7-x86_64
Enable gPXE?                   : 0
Enable PXE Menu?               : 1
Fetchable Files                : {}
Kernel Options                 : {'biosdevname': '0', 'net.ifnames': '0'}
Kernel Options (Post Install)  : {}
Kickstart                      : /var/lib/cobbler/kickstarts/CentOS-7-x86_64.cfg
Kickstart Metadata             : {}
Management Classes             : []
Management Parameters          : <<inherit>>
Name Servers                   : []
Name Servers Search Path       : []
Owners                         : ['admin']
Parent Profile                 : 
Internal proxy                 : 
Red Hat Management Key         : <<inherit>>
Red Hat Management Server      : <<inherit>>
Repos                          : ['newton']
Server Override                : <<inherit>>
Template Files                 : {}
Virt Auto Boot                 : 1
Virt Bridge                    : xenbr0
Virt CPUs                      : 1
Virt Disk Driver Type          : raw
Virt File Size(GB)             : 5
Virt Path                      : 
Virt RAM (MB)                  : 512
Virt Type                      : kvm
</pre>
### System
System就像是一个配置好安装信息的实例 , system 有对应的 profile , hostanme,dns-server,mac 地址 , 定制ip地址 等等
<pre>
cobbler system add --name=linux-node1.example.com --mac=00:50:56:35:9C:3B --profile=CentOS-7-x86_64 --ip-address=192.168.56.102 --subnet=255.255.255.0 --gateway=192.168.56.2 --interface=eth0 --static=1 --hostname=linux-node1.example.com --name-servers="192.168.56.2" --kickstart=/var/lib/cobbler/kickstarts/CentOS-7-x86_64.cfg
</pre>

## cobbler设计方式
Cobbler的配置结构基于一组注册的对象。每个对象表示一个与另一个实体相关联的实体（该对象指向另一个对象，或者另一个对象指向该对象）。当一个对象指向另一个对象时，它就继承了被指向对象的数据，并可覆盖或添加更多特定信息。以下对象类型的定义
<pre>
Distros（发行版）：表示一个操作系统，它承载了内核和initrd的信息，以及内核参数等其他数据
Profile（配置文件）：包含一个发行版、一个kickstart文件以及可能的存储库，还包含更多特定的内核参数等其他数据
Systems（系统）：表示要配给的额机器。它包含一个配置文件或一个景象，还包含IP和MAC地址、电源管理（地址、凭据、类型）、（网卡绑定、设置valn等）
Repository（镜像）：保存一个yum或rsync存储库的镜像信息
Image（存储库）：可替换一个包含不属于此类比的额文件的发行版对象（例如，无法分为内核和initrd的对象）。
</pre>

# Tips
对于很多人担心的生成环境开启DHCP服务问题，我认为不会对现有生产环境产生任何影响，理由有二：

1. 没有人会在装好系统后让网卡使用dhcp模式，通常都是为网卡配置静态ip
2. 从测试过程中看到，就算是服务器默认设置成了通过pxe启动，而且也顺利的通过pxe启动了，但之后会收到cobbler的引导菜单。如果默认没有任何选择的话，20秒后会使用local方式加载，也就是启动硬盘上的系统。
3. 也可以设置默认安装的系统，建立不要设置，如果设置了上面第二个点就不起作用了 `/etc/cobbler/pxe/pxedefault.template`
4.  SNIPPET我理解是一种 kickstart template 的编写的一种模板语言, 用于编写 kickstart template ，cobbler 本身就附带很多SNIPPET,它的路径在 `/var/lib/cobbler/snippets` , ks 文件中提到的SNIPPET 都会去这个路径下寻找.
# 参考

[自动化运维之 ~cobbler~](http://www.cnblogs.com/xiaocen/p/3734767.html)
[cobbler使用](http://blog.csdn.net/allison_ywt/article/details/52682528)

> 另外，cobbler还有web界面和API的使用,web界面可以更容易，API也可用于嵌入其他平台