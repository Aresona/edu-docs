# DHCP
## DHCP简介
DHCP采用客户端/服务器通信模式，由客户端向服务器提出配置申请，服务器返回为客户端分配的IP地址等相应的配置信息，以实现IP地址等信息的动态配置。

> 当DHCP客户端和DHCP服务器处于不同物理网段时，客户端可以通过DHCP中继与服务器通信，获取IP地址及其他配置信息。

## DHCP的IP地址分配

### IP地址分配策略
针对客户端的不同需求，DHCP提供三种IP地址分配策略：

* 手工分配地址：由管理员为少数特定客户端（如WWW服务器等）静态绑定固定的IP地址。通过DHCP将配置的固定IP地址发给客户端。
* 自动分配地址：DHCP为客户端分配租期为无限长的IP地址。
* 动态分配地址：DHCP为客户端分配具有一定有效期限的IP地址，到达使用期限后，客户端需要重新申请地址。绝大多数客户端得到的都是这种动态分配的地址。

# DHCP服务器配置

> DHCP服务器中对于接口的相关配置，目前只能在VLAN接口和Loopback接口上进行。其中，DHCP服务器的subaddress地址池配置不能在Loopback接口上进行。

> DHCP服务器上不能配置DHCP Snooping功能。

## DHCP服务器配置任务简介

* 使能DHCP服务（必选）
* 配置接口工作在DHCP服务器模式（可选）
* 配置DHCP服务器的地址池（必选）
* 配置DHCP的安全功能（可选）
* 配置Option 82的处理方式（可选）

###　使能DHCP服务
<pre>
system-view
dhcp enable
</pre>

### 配置接口工作在DHCP服务器模式
配置接口工作在DHCP服务器模式后，当接口收到HDCP客户端发来的DHCP报文时，将从DHCP服务器的地址池中分配地址。
<pre>
system-view
interface vlan 100
dhcp select server global-pool (可选)
</pre>


## 配置DHCP服务器的地址池
### 任务简介
* 创建DHCP地址池(必选)
* 配置DHCP地址池的地址分配方式(对同一个地址池只能选一个，静态绑定和动态分配)
* 配置DHCP客户端的DNS服务器地址
* 配置DHCP客户端的网关地址
* 配置DHCP自定义选项

### 创建DHCP地址池
<pre>
system-view
dhcp server ip-pool vlan100(必选，默认情况下，没有创建DHCP地址池)
</pre>
### 配置DHCP地址池的地址分配方式
根据客户端的实际需求，可以将地址池配置为彩静态绑定或动态分配方式进行地址分配，但对一个DHCP地址池不能同时配置这两种方式。

动态地址分配需要指定用于分配的地址范围，而静态地址绑定则可以看作只包含一个地址的特殊的DHCP地址池。

#### 配置采用静态绑定方式进行地址分配
<pre>
system-view
dhcp server ip-pool vlan100
static-bind ip-address 192.168.1.2 24
static-bind mac-address 00-00-00-00-00-00
</pre>

> 同一个DHCP地址池中，如果多次执行static-bind ip-address或static-bind mac-address或static-bind client-identifier命令，新的配置会覆盖已有配置。

#### 配置采用动态分配方式进行地址分配

对于采用动态地址分配方式的地址池，需要配置该地址池可分配的地址范围，地址范围的大小通过掩码来设定。目前，一个地址池中只能配置一个地址段。

对于不同的地址池，DHCP服务器可以指定不同的地址租用期限，但同一个DHCP地址池中的地址具有相同的期限。地址租用有效期限不具有继承关系。

<pre>
system-view
dhcp server ip-pool vlan100
network 192.168.1.0 24
expired  { day day [ hour hour [ minute minute ] ] | unlimited }
quit
dhcp server forbidden-ip 192.168.1.10 192.168.1.20 配置不参与自动分配IP地址。
</pre>

> 在同一个DHCP地址池中，如果多次执行network命令，新的配置会覆盖已有配置。

> 多次执行dhcp server forbidden-ip命令，可以配置我个不参与自动分配的IP地址段。

### 配置DHCP客户端的DNS服务器地址
通过域名访问Internet上的主机时，需要将域名解析为IP地直一，这是通过DNS实现的。为了使DHCP客户端能够通过域名访问Internet上的主机，DHCP服务器应在为客户端根本IP地址的同时指定DNS服务器地址。目前，每个DHCP地址池最多可以8个DNS服务器地址。

<pre>
system-view
dhcp server ip-pool vlan100
dns-list 8.8.8.8 223.5.5.5
</pre>

### 配置DHCP客户端的网关地址
DHCP客户端访问本网段以外的服务器或主机时，数据必须通过网关进行转发。DHCP服务器可以在为客户端分配IP地址的同时指定网关的地址。
在DHCP服务器上，可以为每个地址池分别指定客户端对应的网关地址。在给客户端分配IP地址的同时，也将网关地址发送给客户端。目前，每个DHCP地址池最多可以配置8个网关地址。

<pre>
system-view
dhcp server ip-pool vlan100
gateway-list 192.168.1.1
</pre>

# DHCP服务器常见配置错误举例

* 故障现象

客户端从DHCP服务器动态获得的IP地址与其他主机IP地址冲突。

* 故障分析

可能是网络上有主机私自配置了IP地址，导致冲突。
* 处理过程

1. 断开客户端的网线，从另外一台主机执行ping操作，设置较长超时时间，检查网络中是否已经存在该IP地址的主机。
2. 如果能够收到ping操作的响应消息，则说明该IP地址已由用户静态配置。在DHCP服务器上执行dhcp server forbidden-ip命令，禁止该IP地址参与动态地址分配。
3. 连接好客户端的网线，在客户端释放并重新获取IP地址。以Windows XP为例，在Windows环境下运行cmd进入DOS环境，使用ipconfig/release命令释放IP地址，之后使用ipconfig/renew重新获取IP地址。



