## zabbix解决中文乱码问题

* 找出想要使用的字体文件
	* 如在windows下的控制面板－－字体里面就可以找到不少常用字体

* 上传字体到zabbix相应目录 `（/usr/share/zabbix/fonts）` 下，并且把文件名改为小写
* 在配置文件里面修改相应的字体名字并保存 

<pre>
[root@zabbix fonts]# grep FONT_NAME /usr/share/zabbix/include/defines.inc.php
define('ZBX_GRAPH_FONT_NAME',		'msyhbd'); // font file name
define('ZBX_FONT_NAME', 'msyhbd');
</pre>
这里的msyhbd就是字体的名字…