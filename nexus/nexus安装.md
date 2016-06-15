#### 依赖条件

    yum install java-1.8.0 -y

### 开始安装

    useradd nexus
    passwd nexus
	cp nexus-latest-bundle.tar.gz /home/nexus
	su - nexus
    tar xf nexus-latest-bundle.tar.gz
    ln -s nexus-2.13.0-01/ nexus
	mkdir /home/nexus/nexus/wrapper.pidfile

### 配置为服务并启动服务

以root用户执行

    /bin/cp /home/nexus/nexus/bin/nexus /etc/init.d/nexus

修改脚本文件/etc/init.d/nexus的下面几处

	NEXUS_HOME="/home/nexus/nexus"
	RUN_AS_USER=nexus
	PIDDIR="/home/nexus/nexus/wrapper.pidfile"

继续用root用户执行

	chmod 755 /etc/init.d/nexus
	chown root /etc/init.d/nexus
	cd /etc/init.d
	chkconfig --add nexus
	chkconfig nexus on

##### 启动服务

	/etc/init.d/nexus start

### 查看日志

	tail -f /home/nexus/nexus/logs/wrapper.log

## 访问nexus

    192.168.1.xxx:8081/nexus


## 卸载 Nexus

这个服务本身只有两个目录： `nexus` 和  `sonatype-work` 所以卸载的时候只需要把这两个目录删除了，然后再把/etc/init.d/nexus文件删除，如果想删除干净还可以通过chkconfig 把它给去掉。
