# Installation Guide

This manual explains how to boot the Red Hat Enterprise Linux 7.4 installation program (Anaconda) and how to install Red Hat Enterprise Linux 7.4 on AMD64 and Intel 64 systems,64-bit IBM Power Systems servers,and IBM System z.It also covers advanced installation methods such as *Kickstart* installtions,PXE installations,and installtions over VNC.Finally,it describes common post-installtion tasks and explains how to troubleshoot installation problems.

## Getting Started


### Graphical Installation

*Anaconda*是一个红帽的Linux安装器，可以通过它来实现图形界面的安装；

*Anaconda*与其他操作安装程序最大的不同是并行执行。

### Remote Installation

You can use the graphical interface remotely to install Red Hat Enterprise Linux. For headless systems, *Connect Mode* can be used to perform a graphical installation completely remotely. For systems with a display and keyboard, but without the capacity to run the graphical interface, *Direct Mode* can instead be used to facilitate setup.

> A headless system is a computer that operates without a monitor,graphical user interface(GUI) or peripheral(外围) devices, such as keyboard and mouse.


### Automated Installation

Anaconda installations can be automated through the use of a ***Kickstart*** file. Kickstart files can be used to configure any aspect of installation, allowing installation without user interaction, and can be used to easily automate installation of multiple instances of Red Hat Enterprise Linux.

***Kickstart*** files can be automatically created based on choices made using the graphical interface, through the online [Kickstart Generator tool](https://access.redhat.com/labsinfo/kickstartconfig), or written from scratch using any text editor.[For more information](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/installation_guide/sect-kickstart-howto#sect-kickstart-file-create) 

> *Kickstart Generator tool* 支持选择好后点击下载按纽，然后把生成的kickstart file与boot media捆绑在一起，或者一起部署在网络上实现自动化的安装。

安装 ***kickstart generator tool***

<pre>
yum install system-config-kickstart -y
</pre>

运行 *system-config-kickstart*

运行该程序时，我只在xshell里面成功过，图形界面的终端估计也可以，在选包的时候会遇到一个错误，如下： `Package selection is disabled due to problems downloading package infomation` 该错误是由于centos7中的kickstart需要使用自己的包仓库，这时我们只需要在 `/etc/yum.repos.d/` 目录下编辑一个名叫 `development`的仓库就可以了。

<pre>
[root@localhost yum.repos.d]# cat development.repo 
[development]
name=development
baseurl=file:///mnt
enabled=1
gpgcheck=0
</pre>






## Downloading Red Hat Enterprise Linux

There are two basic types of installation media available on the AMD64 and Intel 64 (x86_64) and IBM Power Systems (ppc64) architectures:

**Binary DVD**

A full installation image which can be used to boot the installation program and perform an entire installation without additional package repositories.

**boot.iso**

A minimal boot image which can be used to boot the installation program, but requires access to additional package repositories from which software will be installed. Red Hat does not provide such a repository; you must create it using the full installation ISO image.

**下载镜像**

下载镜像一般有两种方式：

1. 通过在浏览器直接点击镜像名字下载到PC
2. 通过右键复制其URL，然后通过其他应用下载

> 第二种方式一般用于网络不稳定时，因为下载链接包括一个认证的key,它只在一小段时间内有效，如果你中断后重新尝试下载，这个key可能已经失效了。另外，*curl* 之类的工具可以从断点处下载，可以节省时间和流量。

**通过curl下载安装介质**

<pre>
curl -o filename.iso 'copied_link_location'
</pre>

修改上面 *filename.iso*为平台中显示的名字，如果不指定的话，curl下载完的名字最终会指定为URL中的乱码格式。

如果你在下载的过程中确实中断了，这时想要实现断点继传，需要重新找到新的URL地址，并在后面加上 `-C -`，如下：

<pre>
curl -o rhel-server-7.0-x86_64-dvd.iso 'https://access.cdn.redhat.com//content/origin/files/sha256/85/85a...46c/rhel-server-7.0-x86_64-dvd.iso?_auth_=141...963' -C -
</pre>

-------------------
在下载完镜像后，你有五种选择：

1. 把它烧到CD中
2. 生成一个启动U盘
3. 把它放在一台服务器上用来网络安装
4. 放在硬盘上做为安装源
5. 用它来准备一台PXE服务器

## Making MEDIA
在这里首先引入一个新概念叫 **BOOT OPTION** ,默认 *inst.stage2=* 会设置一个默认值为 *hd:LABEL=RHEL7\x20Server.x86_64*. 如果需要自定义的话，一定要确保这个值是正确的。

**BOOT OPTION**有两种格式，一种是`K=V`格式,另外一种是不带`=`的。

一般情况下我们可以通过U盘启动时，按`esc`/`tab`等键进入。

### Making an installation CD or DVD

在刻录时可以选择最小的ISO和完整版的ISO，一般情况下完整版的只能刻到DVD上，而最小版的只有300M，所以可以刻录到CD/DVD。

在选择刻录软件时，一定要注意XP和VISTA系统不支持，window7后的才支持，也可以选择第三方软件。
