# libreswan配置site-to-site模式的VPN

<pre>
ipsec auto --add mysubnet
ipsec auto --add mysubnet6
ipsec auto --add mytunnel
ipsec auto --up mysubnet
ipsec auto --up mysubnet6
ipsec auto --up mytunnel

https://libreswan.org/wiki/Subnet_to_subnet_VPN
https://access.redhat.com/documentation/zh-CN/Red_Hat_Enterprise_Linux/7/html/Security_Guide/sec-Securing_Virtual_Private_Networks.html
http://kb.hillstonenet.com/cn/wp-content/uploads/2015/09/Linux%E4%B8%8B%E4%BD%BF%E7%94%A8Strongswan%E6%90%AD%E5%BB%BAIPSec-VPN%EF%BC%88PSK%E6%96%B9%E5%BC%8F%EF%BC%89.pdf

</pre>