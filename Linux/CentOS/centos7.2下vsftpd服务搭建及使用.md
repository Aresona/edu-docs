# 搭建FTP服务
<pre>
yum install vsftpd -y
</pre>
## 使用系统用户登录
一般情况下，centos7.2系统会自动生成一个ftp的用户，我们需要先给它设置一个密码
<pre>
passwd ftp
ftp
</pre>
找一个目录用来存放文件
<pre>
mkdir /var/lib/ftp
chown -R ftp.root /var/lib/ftp
</pre>

## 使用虚拟用户
首先虚拟用户的用户认证是通过pam方式去认证的，pam文件里面指定认证的db文件，db文件又是通过明文用户名和密码文件生成而来。

**指定pam文件**
`/etc/vsftpd/vsftpd.conf`
<pre>
pam_service_name=vsftpd
</pre>
> 这里的vsftpd指的是文件/etc/pam.d/vsftpd

**`/etc/pam.d/vsftpd`（清空所有配置）**
<pre>
auth required /lib64/security/pam_userdb.so db=/etc/vsftpd/vuser_passwd
account required /lib64/security/pam_userdb.so db=/etc/vsftpd/vuser_passwd
</pre>
> `db=/etc/vsftpd/vuser_passwd`指定了db文件的位置，接下来就是生成db文件，由于db文件是通过明文用户名和密码文件生成而来，所以先创建一个保存明文用户名和密码的文件 `vuser_passwd.txt`

<pre>
[root@openstack-master pub]# cat /etc/vsftpd/vuser_passwd.txt 
ftp
ftp
</pre>
> 奇数行为用户名，偶数行为密码

**生成db文件**

<pre>
cd /etc/vsftpd
db_load -T -t hash -f vuser_passwd.txt vuser_passwd.db
</pre>

到这里，用户的认证就完了，如果要添加新的用度，在编辑 `/etc/vsftpd/vuser_passwd.txt` 后要再次生成一下db文件。然后现在每个用户的具体配置，如指向目录、可读写权限等又是在哪配置的呢，原来它是通过一个用户对应一个配置文件来实现的，且这个文件必须用FTP用户名去做文件名，建一个目录专门存放这些文件：

<pre>
cd /etc/vsftpd
mkdir vuser_conf
cd vuser_conf
cat ftp
local_root=/var/ftp/pub
write_enable=YES
anon_umask=022
anon_world_readable_only=NO
anon_upload_enable=YES
anon_mkdir_write_enable=YES
anon_other_write_enable=YES
</pre>
<pre>
chown ftp.root -R /var/ftp/pub
</pre>
接下来就是根据需要和以上各文件信息来修改配置文件 `/etc/vsftpd/vsftpd.conf` 了，启用或更改改下配置的值

<pre>
anonymous_enable=NO  # 禁用匿名登录
ascii_upload_enable=YES
ascii_download_enable=YES
chroot_local_user=YES  # 启用限定用户在其主目录下
</pre>

以下配置是需要自己手工添加：
<pre>
guest_enable=YES  # 设定启用虚拟用户功能
guest_username=ftp  # 指定虚拟用户的宿主用户，CentOS中已经有内置的ftp用户了
user_config_dir=/etc/vsftpd/vuser_conf  # 虚拟用户配置文件存放的路径
allow_writeable_chroot=YES  # 如果启用了限定用户在其主目录下需要添加这个配置
</pre>