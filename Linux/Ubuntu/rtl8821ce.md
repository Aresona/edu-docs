# 背景
本文章主要记录在 ubuntu 18.04 下安装 rtl8821ae 无线网卡的驱动 
# 操作
* 下载源码包
<pre>
wget https://free-1253146430.cos.ap-shanghai.myqcloud.com/rtl8821ce.zip
</pre>

* 修改 Makefile 文件
<pre>
cd rtl8821ce/
export TopDIR ?= /root/rtl8821ce
</pre>

* 编译安装
<pre>
make
make install
</pre>

* 导入模块
<pre>
modprobe -a 8821ce
</pre>

[参考文档](https://blog.csdn.net/qq_33042187/article/details/80462412)