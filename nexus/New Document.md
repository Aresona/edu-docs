# Apache下配置PHP的两种方式

1. 在lamp体系中，对于apache端php的配置，我们最常用的就是mod_php, 它把PHP做为APACHE一个内置模块。让apache http服务器本身能够支持PHP语言，不需要每一个请求就启动PHP解释器来解释PHP。  
2. 和把webserver与php绑定起来的方式不同，fastcgi是HTTP服务器与你的或其它机器上的程序进行“交谈”的一种工具，相当于一个程序接口。它可以接受来自web服务器的请求，解释输入信息，将处理后的结果返回给服务器(apache,lighty等)。mod_fastcgi就是在apache下支持fastcgi协议的模块。 

## php架构

![](http://laruence-wordpress.stor.sinaapp.com/uploads/php-arch.jpg)

https://secure.php.net/manual/zh/install.fpm.php

http://www.php-internals.com/book/?p=chapt02/02-02-01-apache-php-module

http://ciaos.iteye.com/blog/2123388

http://wenku.baidu.com/link?url=WpHSSuwGw9gushP4G9Yl03IVOx2bgzug_4tlTroL4PCPc5c0jJyTOcHHxSWAcDaoaYIVaH7HOK1kkX0pf-RcUN7RKiiuQwPtXHf04pmuIHC

https://www.zybuluo.com/phper/note/50231

http://blog.csdn.net/hxsstar/article/details/18809771