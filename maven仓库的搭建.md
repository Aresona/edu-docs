# 搭建maven本地库

[Downloading Nexus Repository Manager OSS](http://www.sonatype.com/download-oss-sonatype)

    wget http://www.sonatype.org/downloads/nexus-latest-bundle.tar.gz

* 添加运行用户，并解压包到家目录

<pre>
useradd nexus
tar xf nexus-latest-bundle.tar.gz -C /home/nexus
chown -R nexus.nexus /home/nexus/
su - nexus
ln -s nexus-2.13.0-01/ nexus
</pre>

* 开启nexus服务 

<pre>
/home/nexus/nexus/bin/nexus start
</pre>

* 解压已经存在的包到 `/home/nexus/sonatype-work/nexus/storage` 下

<pre>
rm -rf /home/nexus/sonatype-work/nexus/storage
tar xf storage.tar.gz -C /home/nexus/sonatype-work/nexus/storage
</pre>

* 访问web

<pre>
http://192.168.200.10:8081/nexus
</pre>



maven库地址：192.168.200.10

yum源地址:ftp://192.168.200.10


### 迁移nexus
只需要把原来的storage目录复制到新的目录下就可以了

