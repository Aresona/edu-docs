# 监控部署

## 监控CPU
### 温度监控
**编写检测脚本**

`/backup/scripts/CPU-Temp.sh`
<pre>
#!/bin/bash
/usr/bin/ipmitool -I open sensor get "Temp"|grep degrees|awk '{print $4}'
</pre>

**编写KEY配置文件**

`/etc/zabbix/zabbix_agentd.d/CPU-Temp.conf`
<pre>
UserParameter=CPU_Temp[*],/bin/bash /backup/scripts/CPU-Temp.sh
</pre>

**编写salt状态文件(zabbix-server)**
<pre>
mkdir /srv/salt/zabbix/CPU/files
cp /usr/bin/ipmi /srv/salt/zabbix/CPU/files
cat /srv/salt/zabbix/CPU/cpu-temp.sls 
/usr/bin/ipmitool:
  file.managed:
    - source: salt://zabbix/CPU/files/ipmitool
    - mode: 6755
    - user: root
    - group: root
</pre>

**执行salt状态**
<pre>
salt '192.168.1.202' state.sls zabbix.CPU.cpu-temp
</pre>



## 监控项详解
`system.cpu.util[,softirq]`
linux的中断宏观分为两种：软中断和硬中断。这里的软指跟软件相关的，硬指跟硬件相关的，而不是软件实现和硬件实现的中断。

`agent.hostname`
这个指在配置文件里面的名字

`system.hostname`
这个指系统的主机名
