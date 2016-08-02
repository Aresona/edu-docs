# H3C交换机文件管理及配置管理

[官方文件](http://www.h3c.com.cn/Service/Document_Center/Switches/Catalog/S5120/S5120-SI/Configure/Operation_Manual/H3C_S5120-SI_CG-Release_1101-6W104/201108/723464_30005_0.htm)
## 文件管理
`flash` 表示设备上某块存储介质上的文件。drive表示存储介质的名称，为flash，本设备上只有一个存储介质，可以不用给出存储介质的信息
### 相关命令
<pre>
dir /all
pwd
cd
mkdir 
more
copy
move
delete
undelete
reset recycle-bin 
execute filename(必须以.bat结尾)
fixdisk device
display nandflash file-location filename
file prompt { alert | quiet }
</pre>
### 保存当前配置的两种方式
[官方文档](http://www.h3c.com.cn/Service/Document_Center/Switches/Catalog/S5120/S5120-SI/Configure/Operation_Manual/H3C_S5120-SI_CG-Release_1101-6W104/201108/723464_30005_0.htm#_Ref188960165)

配置的保存方式有两种：

* 快速保存方式，执行不带safely参数的save命令。这种方式保存速度快，但是保存过程中如果出现设备重启、断电等问题，原有配置文件可能会丢失。
* 安全方式，执行带safely参数的save命令。这种方式保存速度慢，即使保存过程中出现设备重启、断电等问题，原有配置文件仍然会保存到设备中，不会丢失。
<pre>
save file-url    ## 将当前配置保存到指定文件，但不会将该文件设置为下次启动配置文件
save [safely][backup|main]   ## 将当前配置保存到存储介质的根目录下，并将该文件设置为下次启动配置文件
</pre>

