
# YUM
YUM是红帽系列在5版本以后用到的一个安装、检测、管理、查询二进制包的软件，在5以前用的是 `up2date`

[官方文档](https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/7/html/System_Administrators_Guide/ch-yum.html)

### 简单用法

* 忽略已经安装的包

<pre>
rpm -Uvh --replacepkgs tree-1.6.0-10.el7.x86_64.rpm
</pre>
这个参数一般会在两种情况下使用；一种是这个包里面的一些文件被删除了，另外一种就是你想要它原始的配置文件。

* 安装一个老的包

<pre>
rpm -Uvh --oldpackage older_package.rpm
</pre>

> 有时，RPM会把你以前的配置文件存储起来，如果你想要的话，可以自己解决它们的依赖关系，一般会存储成后面这种方式 `saving /etc/configuration_file.conf as /etc/configuration_file.conf.rpmsave`

* 关于包组的一些用法

<pre>
yum groups summary
yum group list
yum group info Xfce
yum group list hidden ids ked\*
yum group install "KDE Desktop"
yum group install kde-desktop
yum install @"KDE Desktop"
yum install @kde-desktop
yum group remove "KDE Desktop"
yum group remove kde-desktop
yum remove @"KDE Desktop"
yum remove @kde-desktop
</pre>

### 创建自己的YUM仓库

* 安装createrepo

<pre>
yum install createrepo -y
</pre>

* 把所有需要的包拷贝到一个目录里面 `/mnt/local_repo` 
* 进入到这个目录然后执行下面命令

<pre>
createrepo --database /mnt/local_repo
</pre>

### 通过镜像文件创建一个本地YUM仓库

<pre>
mkdir /media
mount -o loop iso_name /media
cp mount_dir/media.repo /etc/yum.repos.d/new.repo
cp /media/media.repo /etc/yum.repos.d/rhel7.repo
# 编辑repo文件，使它指向本地源
baseurl=file:///media

</pre>

> `-o loop` 的作用是把镜像文件（file） 当做一个block设备

## 通过YUM来下载一个包但是不安装它

有两种方法，一种是通过downloadonly这个插件，另外一个就是通过 `yumdownloader` 这个程序

### 通过插件的方式来实现

* Install the package inclding "downloadonly" plugin:

<pre>
yum install yum-plugin-downloadonly
</pre>

* 通过 `--downloadonly` 参数来只下载不安装

<pre>
yum install --downloadonly --downloaddir=/tmp tree
</pre>


**注意**

如果不指定 `--downloaddir` 参数的话，包会默认下载到/var/cache/yum下

### 通过Yumdownloader来实现

如果想下载一个已经安装上的包，这时候就需要用到 `yumdownloader` 这个程序了

* 安装 `yum-utils` 包

<pre>
yum install yum-utils
</pre>

* 执行命令

<pre>
yumdownloader <package>
</pre>

> 执行上面命令后包默认是存放在当前目录下，可以使用 `--destdir` 选项来指定自定义的目录
> 如果想要一起下载依赖包的话，可以加上参数 `--resolve` 