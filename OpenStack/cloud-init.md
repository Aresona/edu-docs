# Learn Cloud-init

## 什么是Cloud-init?
### Cloud-init 处理模块
* 硬盘配置模块
* 命令执行模块
* 创建用户和组
* 包管理
* 写内容文件

> 另外也支持自己编写python脚本实现功能

### Cloud-init可以做啥？
* 插入 `SSH keys`
* 扩展根分区
* 设置主机名
* 设置root密码
* 设置字符集和时间zone
* 运行自定义脚本


### 数据分类

1.　meta-data 是被cloud平台提供的

2.　user-data 是用户提供的一个自定义的数据块

3.　从数据源检索并存储在 `/var/lib/cloud`


## User-data 实例
### 安装或者更新包
<pre>
#cloud­config
package_upgrade: true
packages:
­ git
­ screen
­ vim­enhanced
</pre>
### 运行自定义命令
<pre>
#cloud­config
runcmd:
­ rhnreg_ks ­­activationkey=3753...
● Or:
#!/bin/bash
rhnreg_ks ­­activationkey=3753...
</pre>

### 包含另外的 `user-data` 文件
<pre>
#include
http://config.example.com/cloud­config
http://config.dept.example.com/cloud­config
</pre>
