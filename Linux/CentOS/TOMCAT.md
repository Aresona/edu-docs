# Tomcat

## JAVA特点
JAVA最优秀的特点是一处写入，到处执行（依赖于JVM虚拟机）；

**JVM**
JVM虚拟机既是提供了许多库的编译环境，也提供JAVA程序的运行环境。而JVM是用C写的，所以很快。

**JDK（Java Development Kit）**

JDK是一个非常重要的工具，专门用来为程序员写程序用的，它包含了JVM

### JAVA技术的三个方向
 * J2SE：Standard Edition
 * J2EE：Enterprise Edition（比J2SE 提供更多工具和库）
 * J2ME：Mobile Edition 很遗憾这个版本到现在搞得不成功

sun公司把JAVA技术卖给Oracle公司后，sun公司开源了JAVA技术并由一个叫openjdk的组织来维护，从些 `JAVA 2SE` 和 `JAVA 2EE` 就出现了。

## Tomcat
Tomcat就是使用了 `JAVA 2SE` 和 `JAVA 2EE` 中的一些组件的一个WEB容器，作用是使得JAVA程序员写的 .jsp 网页都通过tomcat发给客户端。

**tomcat组件**
<pre>
&lt;Server>
　　&lt;Service>　　
　　　　&lt;connector>
　　　　&lt;connector/>
　　　　&lt;Engine>
　　　　　　&lt;Host />
　　　　　　&lt;Host>
　　　　　　　　&lt;Context/>
　　　　　　　　　　...
　　　　　　&lt;/Host>
　　　　&lt;/Engine>
　　&lt;/Service>
&lt;/Server>
</pre>
htpp的请求通过cgi或者java支持的其他协议被发送到server(一个server中可以有多个service）server通过connector（一个service可以有多个connector)发送给Engine（一个service只能包含一个engine）所有工作就在Engine中的Host和Context中完成一个（一个engine可以包含多个host，host下又可包含多个context）

### Openjdk安装
<pre>
yum install java-1.8.0-openjdk -y
yum install java-1.8.0-openjdk-devel -y
</pre>
> openjdk这个包里面只包含了JAVA的运行环境(JRE),如果想安装开发环境的话需要安装openjdk-devel这个包

**查看JAVA程序**
<pre>
[root@python-test alternatives]# which java
/usr/bin/java
[root@python-test alternatives]# ll /usr/bin/java
lrwxrwxrwx 1 root root 22 Nov 20 08:51 /usr/bin/java -> /etc/alternatives/java
[root@python-test alternatives]# ll /etc/alternatives/java
lrwxrwxrwx 1 root root 70 Nov 20 08:51 /etc/alternatives/java -> /usr/lib/jvm/java-1.8.0-openjdk-1.8.0.65-3.b17.el7.x86_64/jre/bin/java
</pre>
> alternatives常用于同一个系统中安装同一软件的多个版本。比如为了开发需要，我需要安装JDK1.4.2，同时还需要JDK1.6.10，我怎么样才能忽略安装路径，按照我自己的意思，使用我想要的Java版本呢？

### 下载并安装tomcat
**相关术语**

terminology | meaning
--- | ---
Context | 一个context表示一个WEB应用

**关键目录**

Directory | meaning
--- | ---
$CATALINA_HOME | 代表tomcat安装的根目录
$CATALINA_BASE | TOMCAT可以通过定义它来配置多个实例，如果只有一个实例的话，跟$CATALINA_HOME是一样的
/bin | 启动、关闭和一些其他的脚本
/conf | 配置文件和相关的DTDs,另外，server.xml是容器的主配置文件 
/logs | 日志目录
/webapps | This is where your webapps go

> 配置文件里面的所有信息都在启动的时候被读取，也就是说任何改变生效都需要重新启动

<pre>
wget http://mirrors.cnnic.cn/apache/tomcat/tomcat-8/v8.5.8/bin/apache-tomcat-8.5.8.tar.gz
mv apache-tomcat-8.5.8.tar.gz /usr/local
tar xf apache-tomcat-8.5.8.tar.gz
ln -s apache-tomcat-8.5.8/ apache-tomcat
</pre>

### 配置环境变量
tomcat是一个JAVA应用，它不会直接使用环境变量，而是通过它的启动脚本来调用，启动脚本通过环境变量来准备启动tomcat的命令。

**CATALINA_HOME**

如果这个变量不存在的话，tomcat启动脚本有自己来逻辑来设置这个变量，但是这个变量也可能在整个生命周期中都不设置，所以推荐明确地设置这个变量。

它应该设置成二进制文件的根目录
<PRE>
echo 'export CATALINA_HOME=/usr/local/apache-tomcat' >> /etc/profile
</PRE>

**CATALINA_BASE**

`CATALINA_BASE`环境变量指定了tomcat生效配置的根目录，它是可选的；为了简化将来的更新和维护建议设置这两个变量为不同的值。具体在多实例部分来说明，默认如果是一个实例的话，它们的value是一样的。

**JRE_HOME和JAVA_HOME**

这些变量是用来指定一个JDK中JRE的位置，以便启动tomcat

`JRE_HOME`用来指定JRE的位置，`JAVA_HOME`用来指定JDK的位置

设置`JAVA_HOME`变量提供访问某些额外的启动选项，而设置`JRE_HOME`后不允许

当这两个变量都设置的话，`JAVA_HOME`会起作用。

<pre>
echo 'JAVA_HOME="/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.65-3.b17.el7.x86_64/"' >> /usr/local/apache-tomcat/bin/setenv.sh
chmod +x setenv.sh
</pre>

**CATALINA_OPTS**
尽管设置了上面这四个变量，但还是有一些其他的变量，这些变量可以通过catalina.sh脚本里面的注释中看到，这里面经常会被用的一个变量是 `CATALINA_OPTS` ,它允许指定一些tomcat启动时的其他参数；

还有一个用的比较少的参数是 `JAVA_OPTS`,它指定的参数可以被用在启动，关闭或其他的命令中。

**CATALINA_PID**

这个变量也会被经常用到，它指定了一个fork出来的tomcat java进程位置文件，设置这个变量可以实现下列功能：

1. 更好的保护不重复启动
2. 当执行标准的shutdown命令没反应时强制终止tomcat进程

**使用setenv.sh脚本**

除了`CATALINA_HOEM`和`CATALINA_BASE`变量，其他所有的变量都可以在这个脚本中指定，一般放在这两个变量下的/bin/目录下，这个文件必须是可读的。默认这个文件是存在的（发现不存在），如果在两个变量里面都有这个文件，那么优先使用 `CATALINA_HOME`变量中的。

<pre>
echo 'JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.65-3.b17.el7.x86_64/' >> /usr/local/apache-tomcat/bin/setenv.sh
echo 'CATALINA_PID="$CATALINA_BASE/tomcat.pid"' >> setenv.sh
</pre>

> 这些所有的变量都只有在用标准脚本启动tomcat的时候才会生效，如果tomcat是以服务的形式安装的话，这些变量就用不到了。


### 启动tomcat
<pre>
$CATALINA_HOME/bin/startup.sh
$CATALINA_HOME/bin/catalina.sh start
</pre>
> 上面这两个命令都可以实现启动

### 关闭tomcat
<pre>
$CATALINA_HOME/bin/shutdown.sh
$CATALINA_HOME/bin/catalina.sh stop
</pre>

### Unix daemon
#### 编译jsvc库
<pre>
cd $CATALINA_HOME/bin
tar xvfz commons-daemon-native.tar.gz
cd commons-daemon-1.0.15-native-src/unix/
./configure --with-java=/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.65-3.b17.el7.x86_64/
make
cp jsvc ../..
cd ../..
</pre>
#### 把tomcat运行在后台
<pre>
CATALINA_BASE=$CATALINA_HOME
cd $CATALINA_HOME
./bin/jsvc \
    -classpath $CATALINA_HOME/bin/bootstrap.jar:$CATALINA_HOME/bin/tomcat-juli.jar \
    -outfile $CATALINA_BASE/logs/catalina.out \
    -errfile $CATALINA_BASE/logs/catalina.err \
    -Dcatalina.home=$CATALINA_HOME \
    -Dcatalina.base=$CATALINA_BASE \
    -Djava.util.logging.manager=org.apache.juli.ClassLoaderLogManager \
    -Djava.util.logging.config.file=$CATALINA_BASE/conf/logging.properties \
    org.apache.catalina.startup.Bootstrap
</pre>
如果是在OSX系统下，可能需要通过 `-jvm server`指定使用server VM

另外jsvc还有一些其他的有用的参数，如 `-user`,使用这个参数可以在后台启动tomcat后把它切换到另外一个非特权用户，并且可以使用特权的端口；当用root用户启动并带着这个参数时，需要disable `org.apache.catalina.security.SecurityListener`检查

`$CATALINA_HOME/bin/daemon.sh`可以当作一个开机启动模板，放在/etc/init.d/下（jsvc)。**没有测试成功**

### JSP工作原理

结合右边给出的流程图：
当客户端浏览器向服务器请求一个 JSP 页面时，服务器收到该请求后，首先检查所请求的这个
JSP 文件内容 ( 代码 ) 是否已经被更新，或者是否是 JSP 文件创建后的第一次被访问，如果是，
那么，这个 JSP 文件就会在服务器端的 JSP 引擎作用下转化为一个 Servlet 类的 Java 源代码
文件。紧接着，这个 Servlet 类会在 Java 编译器的作用下被编译成一个字节码文件，并装载
到 jvm 解释执行。剩下的就等同于 Servlet 的处理过程了。
如果被请求的 JSP 文件内容 ( 代码 ) 没有被修改，那么它的处理过程也等同于一个 Servlet 的
处理过程。即直接由服务器检索出与之对应的 Servlet 实例来处理。

需要注意的是，JSP 文件不是在服务器启动的时候转换成 Servlet 类的。而是在被客户端访问
的时候才可能发生转换的 ( 如 JSP 文件内容没有被更新等，就不再发生 Servlet 转换 )。
就 Tomcat 而言，打开目录 %Tomcat%/work/%您的工程文件目录%，然后会看到里面有 3
个子目录：org/apache/jsp，若没有这 3 个目录，说明项目的 JSP 文件还没有被访问过，
打开进到 jsp 目录下，会看到一些 *_jsp.java 和 *_jsp.class 文件，这就是 JSP 文件被转换成
Servlet 类的源文件和字节码文件了。
有兴趣的话，可以使用浏览器访问服务器中的 JSP，然后观察 JSP 转换 Servlet 以及编译的时机。

![](http://www.blogjava.net/images/blogjava_net/fancydeepin/myself/jsp.png)
# JSP与Servlet

## JSP
JSP(Java Server Pages)是由Sun Microsystems公司倡导、许多公司参与一起建立的一种动态网页技术标准。在传统的网页HTML文件(*.htm,*.html)中插入Java程序段(Scriptlet)和JSP标记(tag)，从而形成JSP文件(*.jsp)。 

简单地说，jsp就是可能包含了java程序段的html文件，为了和普通的html区别，因此使用jsp后缀名。

下面这个图是普通的HTML请求流程：

![](http://images.51cto.com/files/uploadimg/20090707/1422200.jpg)

因为JSP包含了java程序代码段，因此JSP在web server里面就要有个更多的处理步骤。如下图所示：

![](http://images.51cto.com/files/uploadimg/20090707/1422201.jpg)

可以发现，这里多了一个JSP Container的东西，当请求到服务器后首先进入 translation阶段，也就是把请求文件转换成java文件，接下来进入请求文件生成过程，这里也就是编译，把JAVA文件编译成class类文件。然后再返回给客户端。

## Servlet
Servlet是一种独立于平台和协议的服务器端的 `Java应用程序`，可以生成动态的Web页面。 它担当Web浏览器或其他HTTP客户程序发出请求，与HTTP服务器上的数据库或应用程序之间的中间层。


Servlet是位于Web 服务器内部的服务器端的Java应用程序，与传统的从命令行启动的Java应用程序不同，Servlet由Web服务器进行加载，该Web服务器必须包含支持Servlet的Java虚拟机。

在通信量大的服务器上，Java servlet的优点在于它们的执行速度更快于CGI程序。各个用户请求被激活成单个程序中的一个线程，而创建单独的程序，这意味着各个请求的系统开销比较小。

简单地说，servlet就是在**服务器端被执行的java程序**，它可以处理用户的请求，并对这些请求做出响应。Servlet编程是纯粹的java编程，而jsp则是html和java编程的中庸形式，它更有助于美工人员来设计界面。正是如此，所有的jsp文件都将被最终转换成java servlet来执行。

从jsp到java到class，**jsp在首次被请求时是要花费一定的服务器资源的。但庆幸的是，这种情况只发生一次，一旦这个jsp文件被翻译并编译成对应的servlet**，在下次请求来临时，将直接由**servlet来处理**，除非这个jsp已经被修改。

从上面两幅图的比较也可以看出，作为jsp服务器，要比普通的web服务器多出一个`JSP Container`的东西，用来负责jsp的解释执行。对于初学者来说，Tomcat将是一个这种应用服务器的非常好的选择。http://tomcat.apache.org/ 上面列出了最新的tomcat下载。这里推荐解压运行版本，而非安装版本。其实解压运行版本并不比安装版复杂多少，一个JAVA_HOME的环境变量，就足够了。也就是说tomcat是一个servlet容器，只有有了这个容器，用来负责jsp的解释执行。

###  [Servlet的生命周期](http://www.blogjava.net/fancydeepin/archive/2013/09/30/404571.html)
* 加载和实例化

Servlet 容器装载和实例化一个 Servlet。创建出该 Servlet 类的一个实例。

* 初始化

在 Servlet 实例化完成之后，容器负责调用该 Servlet 实例的 init() 方法，在处理用户请求之前，来做一些额外的初始化工作。

* 处理请求

当 Servlet 容器接收到一个 Servlet 请求时，便运行与之对应的 Servlet 实例的 service() 方法，service() 方法再派遣运行与请求相对应的 doXX(doGet，doPost) 方法来处理用户请求。

* 销毁

当 Servlet 容器决定将一个 Servlet 从服务器中移除时 ( 如 Servlet 文件被更新 )，便调用该 Servlet 实例的 destroy() 方法，在销毁该 Servlet 实例之前，来做一些其他的工作。其中，(1)(2)(4) 在 Servlet 的整个生命周期中只会被执行一次。

> Servlet 没有 main 方法，不能够独立的运行，它的运行需要容器的支持，Tomcat 是最常用的 JSP/Servlet 容器。
Servlet 运行在 Servlet 容器中，并由容器管理从创建到销毁的整个过程。

## Servlet的工作原理

结合右边给出的流程图：
当客户端浏览器向服务器请求一个 Servlet 时，服务器收到该请求后，首先到容器中检索与请求
匹配的 Servlet 实例是否已经存在。若不存在，则 Servlet 容器负责加载并实例化出该类 Servlet
的一个实例对象，接着容器框架负责调用该实例的 init() 方法来对实例做一些初始化工作，然后
Servlet 容器运行该实例的 service() 方法。
若 Servlet 实例已经存在，则容器框架直接调用该实例的 service() 方法。
service() 方法在运行时，自动派遣运行与用户请求相对应的 doXX() 方法来响应用户发起的请求。
通常，每个 Servlet 类在容器中只存在一个实例，每当请求到来时，则分配一条线程来处理该请求。

![](http://www.blogjava.net/images/blogjava_net/fancydeepin/myself/servlet.png)

### Servlet 与 JSP
JSP 本质是一个 Servlet，它的运行也需要容器的支持。
在 JSP 和 Servlet 文件中都可以编写 Java 和 HTML 代码，不同的是，
Servlet 虽然也可以动态的生成页面内容，但更加偏向于逻辑的控制。
JSP 最终被转换成 Servlet 在 jvm 中解释执行，在 JSP 中虽然也可以编写 Java 代码，但它更加偏向于页面视图的展现。
在 MVC 架构模式中，就 JSP 和 Servlet 而言，C 通常由 Servlet 充当，V 通常由 JSP 来充当。


JDK的安装
<pre>
cd /usr/local/src && tar zxf jdk-8u45-linux-x64.tar.gz && mv jdk1.8.0_45 /usr/local/jdk && chown -R root.root /usr/local/jdk
</pre>
`/etc/export`
<pre>
export JAVA_HOME=/usr/local/jdk
export PATH=$JAVA_HOME/bin:$JAVA_HOME/jre/bin:$PATH
expot CALSSPATH=.$CLASSPATH:$JAVA_HOME/lib:$JAVA_HOME/jre/lib:$JAVA_HOME/lib/tools.jar
TOMCAT_HOME=/usr/local/tomcat
</pre>
TOMCAT安装
<pre>
cd /usr/local/src
tar xf apache-tomcat-8.0.23.tar.gz 
mv apache-tomcat-8.0.23 /usr/local/tomcat
chown -R root.root /usr/local/tomcat
echo 'TOMCAT_HOME=/usr/local/tomcat' >> /etc/profile

</pre>

TOMCAT有两种连接类的引擎，一种是HTTP的，另外一种是AJP；用nginx做代理的话一般会用HTTP的连接器，如果用的是apache的话一般会用AJP的连接器。所以我们要用哪个就把另一个关了。
不建议在一个TOMCAT里面跑多个虚拟主机的方式。因为它们用的是一个JVM，出问题的话不容易排除

unpackWARs="true" autoDeploy="true"

这两个功能一般关掉，因为它有时候可能不工作。每次部署都重启。


###　Manager
`tomcat-user.xml`
<pre>
<role rolename="manager-gui" />
<role rolename="admin-gui" />
<user username="tomcat" password="tomcat" roles="manager-gui,admin-gui" />
</pre>
<pre>
./shutdown.sh
./startup.sh
</pre>
因为之前的管理有好多的漏洞，所以导致会被入侵，还有就是弱命令等。

另外还有一个server status的功能，可以看到一些JVM的状态，生产的时候通过其他方式来获取到这些信息。

### Tomcat安全规范
tomcat默认的参数是给开发用的，不适合生产环境

1. telnet管理端口保护（强制）
2. AJP连接端口保护（强制）
3. 禁用管理端（全删掉）
4. 降权启动
5. 文件列表访问控制
6. 版本信息隐藏（隐藏错误页面）
7. 