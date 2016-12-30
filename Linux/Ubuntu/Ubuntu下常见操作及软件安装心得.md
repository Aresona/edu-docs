### 安装vnc客户端
<pre>
apt-get install vnc4-common xvnc4viewer -y
</pre>

### 安装rdesktop客户端
<pre>
sudo apt-get install rdesktop -y
</pre>

### 安装scrt
<pre>
sudo apt-get install scrt
exit
sudo dpkg -i scrt-8.0.3-1183.ubuntu13-64.x86_64.deb 
wget http://download.boll.me/securecrt_linux_crack.p
wget http://download.boll.me/securecrt_linux_crack.pl
ls
which SecureCRT
sudo perl securecrt_linux_crack.pl /usr/bin/SecureCRT 
</pre>

### 安装SSH服务端
<pre>
sudo apt-get install openssh-server
ps -ef|grep ssh
sudo perl securecrt_linux_crack.pl /usr/bin/SecureCRT 
</pre>

### 安装网易音乐
<pre>
sudo apt-get-repository ppa:hzwhuang/ss-qt5
sudo dpkg -i netease-cloud-music_1.0.0_amd64_ubuntu16.04.deb
</pre>

### 安装QQ
<pre>
sudo dpkg -i fonts-wqy-microhei_0.2.0-beta-2_all.deb 
sudo dpkg -i ttf-wqy-microhei_0.2.0-beta-2_all.deb 
dpkg -i wine-qqintl_0.1.3-2_i386.deb 
<pre>

### 安装 `Chrome`
<pre>
sudo dpkg -i google-chrome-stable_current_amd64.deb 
</pre>

### 配置静态IP
`/etc/network/interfaces`
<pre>
# interfaces(5) file used by ifup(8) and ifdown(8)
auto lo
iface lo inet loopback
auto enp3s0f1
#iface enp3s0f1 inet dhcp
iface enp3s0f1 inet static
address 192.168.33.26
netmask 255.255.255.0
gateway 192.168.33.1
network 192.168.33.0
broadcast 192.168.33.255
dns-nameservers 223.5.5.5 223.6.6.6
</pre>

