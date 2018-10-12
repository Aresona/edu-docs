## ubuntu 下调整双屏

## MariaDB
<pre>
apt-get install mariadb-server -y
cp -a /var/lib/mysql /data
</pre>
<pre>
# edit /etc/mysql/mariadb.conf.d/50-server.cnf
datadir=/data/mysql
bind-address            = 0.0.0.0 
systemctl restart mariadb
</pre>
<pre>
mysql 
grant all privileges on *.* to root@'localhost' identified by 'translink';
grant all privileges on *.* to root@'%' identified by 'translink';
CREATE DATABASE `esports_x_training` /*!40100 DEFAULT CHARACTER SET utf8 */;
quit
</pre>
<pre>
xrandr --output HDMI-1-2 --auto --left-of eDP-1-1
</pre>

## MySQL
<pre>
apt-get install mysql-server -y
systemctl stop mysql
cp -a /var/lib/mysql /data
</pre>
<pre>
# edit /etc/mysql/mysql.conf.d/mysqld.cnf
datadir=/data/mysql
bind-address            = 0.0.0.0 
systemctl restart mysql
# edit /etc/apparmor.d/usr.sbin.mysqld 
# Allow data dir access
  /data/mysql/ r,
  /data/mysql/** rwk,
# edit /etc/apparmor.d/abstractions/mysql
   /data/mysql{,d}/mysql{,d}.sock rw,
systemctl restart apparmor
systemctl restart mysql
</pre>
<pre>
mysql 
grant all privileges on *.* to root@'%' identified by 'translink';
CREATE DATABASE `esports_x_training` /*!40100 DEFAULT CHARACTER SET utf8 */;
quit
</pre>


## Nginx
<pre>
docker pull nginx
docker run -d -p 80:80 -v /data/:/usr/share/nginx/html --name test1 test
docker run -d -p 8081:80 -v /data/nginx:/usr/share/nginx/html --name nginxtest nginx
docker run -d -p 3000:3000 -v /var/www/html/TrainingMatch:/mnt --name nodetest node yarn start /mnt
</pre>

## java镜像
<pre>
修改 apt 源
apt-get clean all
apt-get update
apt-get install python3
apt-get install ffmpeg
apt-get install python3-pip
pip3 install pillow
pip3 install opencv_python
apt-get install libsm6 libxext6
pip3 install pytesseract
apt-get install libtesseract-dev tesseract-ocr

</pre>
### 复制训练数据与配置到 tesseract

<pre>
mkdir /opt/scripts
mkdir ~/db/training -p
mkdir /var/www/html/output/videos -p
mkdir /var/www/html/output/events
mkdir /jar
</pre>

python3 /data/java/scripts/get_rtmp_stream.py /data/nginx/output/events  /usr/share/tesseract-ocr/4.00/tessdata rtsp://192.168.28.17/second 20180928114710606 /opt/scripts 290
python3 /opt/scripts/get_rtmp_stream.py /var/www/html/output/events  /usr/share/tesseract-ocr/4.00/tessdata rtsp://192.168.28.17/second 20180928114710606 /opt/scripts 290

## 运行 java 镜像
<pre>
docker run -p 8089:8089 -v /opt/scripts:/opt/scripts -v /root/db:/root/db -v /var/www/html/output:/var/www/html/output -v /jar:/jar --name javatest java:v1 'java -jar /jar/ training-0.0.1-SNAPSHOT.jar'
docker run -d -p 8092:8089 -v /opt/scripts:/opt/scripts -v /root/db:/root/db -v /var/www/html/output:/var/www/html/output -v /jar:/jar --name javatest2 java:v1 java -jar /jar/training-0.0.1-SNAPSHOT.jar
docker run -d -p 8093:8089 -v /opt/script:/opt/scripts -v /tmp/db:/root/db -v /tmp/output:/var/www/html/output -v /jar3:/jar --name javatest3 java:v1 java -jar /jar/training-0.0.1-SNAPSHOT.jar
docker run -d -p 8094:8089 -v /tmp/test/script:/opt/scripts -v /tmp/test/db:/root/db -v /tmp/test/output:/var/www/html/output -v /tmp/jar3:/jar --name javatest3 java:v1 java -jar /jar/training-0.0.1-SNAPSHOT.jar
</pre>

## 打包
<pre>
mvn clean
mvn package -Dmaven.test.skip=true
</pre>

## 前端代码 build
<pre>
yarn
yarn add hls.js
yarn add reflv
npm install reflv
yarn add react-app-rewired
yarn build
yarn start
</pre>

## [CUDA 安装](https://docs.nvidia.com/cuda/cuda-installation-guide-linux/)
<pre>
https://developer.nvidia.com/cuda-downloads
wget https://developer.nvidia.com/compute/cuda/10.0/Prod/local_installers/cuda-repo-ubuntu1604-10-0-local-10.0.130-410.48_1.0-1_amd64
dpkg -i cuda-repo-ubuntu1604-10-0-local-10.0.130-410.48_1.0-1_amd64.deb 
sudo apt-key add /var/cuda-repo-10-0-local-10.0.130-410.48/7fa2af80.pub
apt-get update
apt-get install cuda
reboot
/usr/local/cuda/extras/demo_suite/deviceQuery
</pre>

## 参考文档
<pre>
https://my.oschina.net/u/2950272/blog/1796874
http://notes.maxwi.com/2017/02/26/ubuntu-cuda8-env-set/
https://developer.nvidia.com/cuda-downloads?target_os=Linux&target_arch=x86_64&target_distro=Ubuntu&target_version=1604&target_type=deblocal
https://developer.nvidia.com/ffmpeg
</pre>

### 编译 ffmpeg
<pre>
apt-get install yasm
git clone https://git.videolan.org/git/ffmpeg/nv-codec-headers.git
cd nv-codec-headers
make
sudo make install
cd ..
git clone https://github.com/FFmpeg/FFmpeg ffmpeg -b master
cd ffmpeg
./configure --enable-cuda --enable-cuvid --enable-nvenc --enable-nonfree --enable-libnpp --extra-cflags=-I/usr/local/cuda/include --extra-ldflags=-L/usr/local/cuda/lib64
make -j 10
make -j 10 install
mkae -j 10 distclean
</pre>

## test
<pre>
python3 /opt/scripts/ff-pull.py /usr/bin/ffmpeg rtsp://192.168.31.168/first /var/www/html/output/videos/20180920093601044_0.flv 0
./ffmpeg -c:v h264_cuvid -i rtsp://192.168.31.168/third -strict -2 -c:v h264_nvenc -f mp4 -y /tmp/demo2.mp4
</pre>

## 新系统处理
<pre>
apt-get install curl -y
curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash -
sudo apt-get install -y nodejs
apt-get install -y npm
npm install yarn -g
mkdir /data/nginx -p
mkdir /data/nginx/output/videos -p
mkdir /data/nginx/output/events -p
mkdir /data/java
mkdir /data/node
mkdir /root/db
git clone http://119.23.246.221/binbin.ren/TrainingMatch.git
cd TrainingMatch
git checkout dev
cd /tmp
git clone http://119.23.246.221/mengyan.li/extreme-box-training.git
cd extreme-box-training
apt-get install -y maven 
mvn clean
mvn package -Dmaven.test.skip=true
cp target/training-0.0.1-SNAPSHOT.jar /data/java/jar/
docker run -p 8089:8089 -v /data/java/scripts:/opt/scripts -v /root/db:/root/db -v /data/nginx/output:/var/www/html/output -v /data/java/jar:/jar --name javatest java:v1 'java -jar -D/jar/training-0.0.1-SNAPSHOT.jar'
docker run -d -p 8089:8089 -v /data/java/scripts:/opt/scripts -v /data/nginx/output:/var/www/html/output -v /data/java/jar:/jar --name javatest java:v1 java -jar /jar/training-0.0.1-SNAPSHOT.jar --ex.http.server.ip="192.168.31.36" --ex.rtmp.server.ip="192.168.28.17"
docker run -d --restart=always -p 8081:80 -v /data/nginx:/usr/share/nginx/html --name nginxtest nginx
docker run -d --restart=always -p 3000:3000 -v /data/node/TrainingMatch:/mnt --name nodetest node yarn --cwd=/mnt start
docker run -d --restart=always -p 8089:8089 -v /data/java/scripts:/opt/scripts -v /data/nginx/output:/var/www/html/output -v /data/java/jar:/jar -v /data/java/src/extreme-box-training/scripts/Arial1.traineddata:/usr/share/tesseract-ocr/4.00/tessdata/Arial1.traineddata --name javanew java:v2 java -jar /jar/training-0.0.1-SNAPSHOT.jar --ex.http.server.ip="192.168.31.36" --ex.rtmp.server.ip="192.168.28.17"
docker run -d --restart=always -p 8089:8089 -v /data/java/scripts:/opt/scripts -v /data/nginx/output:/var/www/html/output -v /data/java/jar:/jar -v /data/java/src/extreme-box-training/scripts/Arial1.traineddata:/usr/share/tesseract-ocr/4.00/tessdata/Arial1.traineddata -v /data/java/src/extreme-box-training/scripts/heb.traineddata:/usr/share/tesseract-ocr/4.00/tessdata/heb.traineddata --name javanew java:v2 java -jar /jar/training-0.0.1-SNAPSHOT.jar --ex.http.server.ip="192.168.31.36" --ex.rtmp.server.ip="192.168.28.17"
docker run -d --restart=always -p 8089:8089 -v /data/java/scripts:/opt/scripts -v /data/nginx/output:/var/www/html/output -v /data/java/jar:/jar -v /data/java/src/extreme-box-training/scripts/Arial1.traineddata:/usr/share/tesseract-ocr/4.00/tessdata/Arial1.traineddata -v /data/java/src/extreme-box-training/scripts/heb.traineddata:/usr/share/tesseract-ocr/4.00/tessdata/heb.traineddata -v /data/java/src/extreme-box-training/scripts/chi_sim.traineddata:/usr/share/tesseract-ocr/4.00/tessdata/chi_sim.traineddata --name javanew java:v2 java -jar /jar/training-0.0.1-SNAPSHOT.jar --ex.http.server.ip="192.168.31.36" --ex.rtmp.server.ip="192.168.28.17"
docker run -d --restart=always -p 8089:8089 -v /data/java/scripts:/opt/scripts -v /data/nginx/output:/var/www/html/output -v /data/java/jar:/jar -v /data/java/src/extreme-box-training/scripts/Arial1.traineddata:/usr/share/tesseract-ocr/4.00/tessdata/Arial1.traineddata -v /data/java/src/extreme-box-training/scripts/heb.traineddata:/usr/share/tesseract-ocr/4.00/tessdata/heb.traineddata -v /data/java/src/extreme-box-training/scripts/chi_sim.traineddata:/usr/share/tesseract-ocr/4.00/tessdata/chi_sim.traineddata --name javanew java:v2 java -jar /jar/training-0.0.1-SNAPSHOT.jar --ex.http.server.ip="192.168.31.36" --ex.rtmp.server.ip="192.168.28.17"
docker run -d --restart=always -p 8089:8089 -v /data/java/scripts:/opt/scripts -v /data/nginx/output:/var/www/html/output -v /data/java/jar:/jar -v /data/java/src/extreme-box-training/scripts/Arial1.traineddata:/usr/share/tesseract-ocr/4.00/tessdata/Arial1.traineddata -v /data/java/src/extreme-box-training/scripts/heb.traineddata:/usr/share/tesseract-ocr/4.00/tessdata/heb.traineddata -v /data/java/src/extreme-box-training/scripts/chi_sim.traineddata:/usr/share/tesseract-ocr/4.00/tessdata/chi_sim.traineddata --name javanew java:v2 java -jar /jar/training-0.0.1-SNAPSHOT.jar --ex.rtmp.server.ip="192.168.28.17"
docker run -d --restart=always -p 8089:8089 -v /data/java/scripts:/opt/scripts -v /data/nginx/output:/var/www/html/output -v /data/java/src/extreme-box-training/target:/jar -v /data/java/scripts/Arial1.traineddata:/usr/share/tesseract-ocr/4.00/tessdata/Arial1.traineddata -v /data/java/scripts/heb.traineddata:/usr/share/tesseract-ocr/4.00/tessdata/heb.traineddata -v /data/java/scripts/chi_sim.traineddata:/usr/share/tesseract-ocr/4.00/tessdata/chi_sim.traineddata --name javanew java:v2 java -jar /jar/training-0.0.1-SNAPSHOT.jar  --ex.rtmp.server.ip="192.168.28.17"
docker run -it  -v /build:/jar --name javanew1  java:v2 /bin/bash
</pre>

## 残留问题
1. 脚本与代码中的同步
2. 僵尸进程
3. 映射(包括实现和是否合理问题)
4. 整个快速部署的脚本
5. 建鹏脚本中的固定IP
6. 视频定时清理
7. teamviewer开机自启动

## windows 下 vscode 配置信息
<pre>

{
    "editor.fontSize": 20,
    "workbench.colorTheme": "Default Light+",
    "vim.disableExtension":false,
    "fileheader.Author": "binbin",
    "fileheader.LastModifiedBy": "binbin",
    "fileheader.tpl": "# -*- coding:utf-8 -*-\r\n# @Author: {author} \r\n# @Date: {createTime} \r\n# @Last Modified by:   {lastModifiedBy} \r\n# @Last Modified time: {updateTime} \r\n",
    "vim.insertModeKeyBindings": [
        {
            "before": ["j", "k"],
            "after": ["<ESC>"]
        }
    ],
    "vim.useSystemClipboard": true
}
</pre>

# ubuntu 配置
## 配置 theme
1. 在 software 里面搜索 communitheme, 并安装
2. 重启电脑，在登陆时点设置，并选择 communitheme snap。

## ssh tunnel
内网主机
<pre>
ssh -NfR 1234:localhost:22 git.esports-x.cn
</pre>
访问内网主机
<pre>
ssh git.esports-x.cn
ssh -p 1234 binbin@localhost
</pre>
ssh免密钥
<pre>
# 服务器
useradd test
passwd test        # TransLink@A1
# 客户端
ssh-keygen
# copy id_rsa.pub to server side /home/test/.ssh/authorized_keys
su - test
chmod 600 ~/.ssh/authorized_keys
</pre>
[开机自启动](http://www.r9it.com/20180613/ubuntu-18.04-auto-start.html)
<pre>
# edit /lib/systemd/system/rc.local.service
[Install]
WantedBy=multi-user.target
Alias=rc-local.service
# touch /etc/rc.local
#!/bin/sh
/usr/bin/ssh -NfR 1234:localhost:22 test@119.23.246.221
touch ~/hehe11
exit 0
chmod +x /etc/rc.local
# create symbol link
ln -s /lib/systemd/system/rc.local.service /etc/systemd/system/
</pre>





