# Tomcat

## 术语（teminology)
Context - In a nutshell, a Context is a web application.
一个上下文就是一个WEB应用
## 目录和文件 

* `$CATALINA_HOME`    Tomcat 安装根目录
* `$CATALINA_BASE`	   当配置多实例的时候，需要为每个实例配置这个变量;如果没有配置多实例的时候，上面这两个目录是一样的。

### Tomcat 关键目录

* **/bin** 	 	这个目录下面是一些.sh的脚本文件，用来实现启动关闭等功能。
* **/conf**		配置文件和相关的DTDs.这里面最重要文件是`server.xml`,它是容器的主要配置文件。
* **/logs**		默认的日志路径
* **/webapps**		webapps默认去的路径

## 配置Tomcat

任何对配置文件的修改如果想生效，必须重启容器（Tomcat)


