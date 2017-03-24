一般我们在安装系统的时候都会选择最小化安装，因为这样最小化的原则可以让我们对服务器运行状况更清楚。但是，后期我们可以偏偏需要用到图形界面，这时候我们只需要安装一些包就可以了。

<pre>
yum groupinstall "GNOME Desktop"
yum groupinstall "Graphical Administration Tools"
</pre>
### CentOS7下面的一些坑
有时候通过 `yum groupinstall "Graphical Administration Tools" ` 的时候它会提示什么 `yum group mark install`这类的，其实是yum在CentOS7里面的变化，有些包不是必须的它就不会安装，这时我们需要指定需要的参数来实现，如下：

<pre>
yum groups install "Graphical Administration Tools" --setopt=group_package_types=conditional,optional
</pre>



### 卸载问题
另外有时候在装上这些包组件后会发现卸载不掉，我在网上找到的一个办法是在 `/etc/yum.conf`文件里面加入下面这行参数，然后再卸载

<pre>
group_command=simple
</pre>

另外还有一个技巧是在centos7下面每个包组都有一个自己的 `Environment-Id` ,如下

<pre>
[root@server03 ~]# yum groupinfo -v "GNOME Desktop"
Loading "fastestmirror" plugin
Loading "langpacks" plugin
Adding en_US to language list
Config time: 0.025
Adding en_US to language list
Yum version: 3.4.3
Setting up Package Sacks
Loading mirror speeds from cached hostfile
 * base: mirrors.aliyun.com
 * extras: mirrors.aliyun.com
 * updates: mirrors.aliyun.com
pkgsack time: 0.019
rpmdb time: 0.001
group time: 0.142

Environment Group: GNOME Desktop
 Environment-Id: gnome-desktop-environment
 Description: GNOME is a highly intuitive and user friendly desktop environment.
 Mandatory Groups:
   base
   core
   desktop-debugging
   dial-up
   directory-client
   fonts
   gnome-desktop
   guest-agents
   guest-desktop-agents
   input-methods
   internet-browser
   java-platform
   multimedia
   network-file-system-client
   networkmanager-submodules
   print-client
   x11
 Optional Groups:
   backup-client
   gnome-apps
   internet-applications
   legacy-x
</pre>

这时候我们就可以通过这些ID来安装了相应的包，如

<pre>
yum groupinstall @^gnome-desktop-environment
</pre>