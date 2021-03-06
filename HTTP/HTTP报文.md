# HTTP报文

如果说HTTP是因特网的信使，那么HTTP报文就是它用来搬东西的包裹了。

## 报文流

HTTP报文是在HTTP应用程序之间发送的数据块。这些数据块以一些文本形式的元信息(meta-information)开头，这些信息描述了报文的内容及含义，后面跟着可选的数据部分。这些报文在客户端、服务器和代理之间流动。术语"流入"、"流出"、"上游"、"下游"都是用来描述报文方向的。

### 报文注入源端服务器

HTTP使用术语流入(inbound)和流出(outbound)来描述事务处理(transaction)的方向。报文流入源端服务器。工作完成之后，会流回用户的Agent代理中。

### 报文向下游流动

HTTP报文会像河水一样流动。不管是请求报文还是响应报文，所有报文都会向下游(downstream)流动。所有报文的发送者都在接收者的上游(upstream)。对于请求报文来说，代理1位于代理3的上游，但对响应报文来说，它就位于代理3的下游。没有报文会向上游流动。

> 术语上游和下游都只与发送者和接收者有关。我们无法区分报文是发送给源端服务器还是发送给客户端的，因为两者都是下游节点。

## 报文的组成部分

### 报文的语法
每条报文都包含一条来自客户端的请求，或者一条来自服务器的响应。它们由三个部分组成：start line 、header 、 body;

实体的主体或报文的主体(或者就称为主体)是一个可选的数据块。与起始行和首部不同的是，主体中可以包含文本或二进制数据，也可以为空。一般 `content-type` 说明了主体是什么。`content-length`说明了有多大，单位是字节。


- 首部(header)

可以有零个或多个首部，每个首部都包含一个名字，后面跟着一个冒号(:)，然后是一个可选的空格，接着是一个值，最后是一个CRLF。首部是由一个空行结束的，表示了首部列表的结束和实体主体部分的开始。有些HTTP版本，如HTTP/1.1,要求有效的请求或响应报文中必须包含特定的首部。

- 实体的主体部分(entity-body)

实体的主体部分包含一个由任意数据组成的数据块。并不是所有的报文都包含实体的主体部分，有时，报文只是以一个CRLF结束。

### 起始行

所有的HTTP报文都以一个起始行作为开始。请求报文的起始行说明了要做些什么。响应报文的起始行说明发生了什么。

#### 请求行

请求报文请求服务器对资源进行一些操作。请求报文的起始行，或称为请求行，包含了一个方法和一个请求的URL，这个方法描述了服务器应该执行的操作，请求URL描述了对哪个资源执行这个方法。

#### 响应行

响应报文承载了状态信息和操作产生的所有结果数据，将其返回给客户端。响应报文的起始行，或称为响应行，包含了响应报文使用的HTTP版本、数字状态码，以及描述操作状态的文本形式的原因短语。

#### 方法

请求的起始行以方法作为开始，方法用来告知服务器要做些什么。常见的HTTP方法如下：

方法 | 描述 | 是否包含主体
--- | ---| ---
GET | 从服务器获取一份文档 | 否
HEAD | 只从服务器获取文档的首部 | 否
POST | 向服务器发磅需要处理的数据 | 是
PUT | 将请求的主体部分存储在服务器上 | 是
TRACE | 对可能经过代理服务器传送到服务器上去的报文进行追踪 | 否
OPTIONS | 决定可以在服务器上执行哪些方法 | 否
DELETE | 从服务器上删除一份文档 | 否

并不是所有服务器都实现了上面7种方法。而且，由于HTTP设计得易于扩展，所以除了这些方法之外，其他服务器可能还会实现一些自己的请求方法。这些附加的方法是对HTTP规范的扩展，因此被称为扩展方法。

#### 状态码

状态码便于程序进行差错处理，而原因短语则更便于人们理解。

可以通过三位数字代码对不同状态码进行分类。200到299之间的状态码表示成功。200到399之间的代码表示资源已经被移走了。400到499之间的代码表示客户端的请求出错了。500到599之间的代码表示服务器出错了。

整体范围 | 已定义范围 |  分类
--- | --- | ---
100~199 | 100~101 | 信息提示
200~299 | 200~206 | 成功
300~399 | 300~305 | 重定向
400~499 | 400~415 | 客户端错误
500~599 | 500~515 | 服务器错误

当前的HTTP版本只为每类状态定义了几个代码。随着协议的发展，HTTP规范中会正式地定义更多的状态码。如果收到了一不认识的状态码，可能是有人将其作为当前协议的扩展定义。可以根据其所处范围，将它作为那类别中一个普通的成员来处理。

### 首部

HTTP规范定义了几种首部字段。应用程序也可以随意发明自己所用的首部。HTTP首部可以分为以下几类。

#### 首部分类

分类 | 描述
--- | ---
通用首部 | 既可以出现在请求报文中，也可以出现在响应报文中
请求首部 | 提供更多有关请求的信息
响应首部 | 提供更多有关响应的信息
实体首部 | 描述主体的长度和内容，或者资源自身
扩展首部 | 规范中没有定义的新首部

#### 首部延续行

将长的首部行分为多行可以提高可读性，多出来的每行前面至少要有一个空格或制表符(tab)。如：

<pre>
HTTP/1.0 200 OK
Content-Type: image/gif
Content-Length: 8572
Server: Test Server
	Version 1.0
</pre>

该首部的完整值为 `Test Server Version 1.0

#### 实体的主体部分

HTTP报文的第三部分是可选的实体主体部分。实体的主体是HTTP报文的负荷。就是HTTP要传输的内容。

HTTP报文可以承载很多类型的数字数据：图片、视频、HTML文档、软件应用程序、信用卡事务、电子邮件等。

## 方法 

### 安全方法 

HTTP定义了一组被称为安全方法的方法。GET方法和HEAD方法都被认为是安全的，这就意味着使用GET或HEAD方法的HTTP请求都不会产生什么动作。

不产生动作，在这里意味着HTTP请求不会在服务器上产生什么结果。

### GET

GET是最常用的方法。通常用于请求服务器发送某个资源。HTTP/1.1要求服务器实现此方法。

### HEAD

HEAD方法与GET方法的行为很类似，但服务器在响应中只返回首部。不会返回实体的主体部分。这就允许客户端在未获取实际资源的情况下，对资源的首部进行检查。使用HEAD，可以：

* 在不获取资源的情况下了解资源的情况（比如，判断其类型）
* 通过查看响应中的状态码，看看某个对象是否存在
* 通过查看首部，测试资源是否被修改了。

服务器开发者必须确保返回的首部与GET请求所返回的首部完全相同。

### PUT
与GET从服务器读取文档相反，PUT方法会向服务器写入文档。有些发布系统允许用户创建WEB页面，并用PUT直接将其安装到WEB服务器上去。

PUT方法的主义就是让服务器用请求的主体部分来创建一个由所请求的URL命名的新文档，或者，如果那个URL已经存在的话，就用这个主体来替代它。

因为PUT允许用户对内容进行修改，所以很多web服务器都要求在执行PUT之前，用密码登录。

### POST

POST方法真实是用来向服务器输入数据的。实际上，通常会用它来支持HTML的表单。表单中填好的数据通常会被送给服务器，然后由服务器将其发送到它要云的地方(比如，送到一个服务器网关程序中，然后由这个程序对其进行处理)。

> POST用于向服务器发送数据。PUT用于向服务器上的资源(例如文件)中存储数据。


### TRACE

客户端发起一个请求时，这个请求可能要穿过防火墙、代理、网关或其他一些应用程序。每个中间节点都可能会修改原始的HTTP请求。TRACE方法允许客户端在最终将请求发送给服务器时，看看它变成了什么样子。

TRACE请求会在目的服务器端发起一个"环回"诊断。行程最后一站的服务器会弹回一条TRACE响应，并在响应主体中携带它收到的原始请求报文。这样客户端就可以查看在所有中间HTTP应用程序组成的请求／响应链上，原始报文是否，以及如何被毁坏或修改过。

TRACE方法主要用于诊断；也就是说，用于验证请求是否如愿穿过了请求／响应链。它也是一种很好的工具，可以用来查看代理和其他应用程序对用户请求所产生效果。

尽管TRACE可以很方便地用于诊断，但它确实也有缺点，它假定中间应用程序对各种不同类型请求(不同的方法－－GET、HEAD、POST等)的处理是相同的。很多HTTP应用程序会根据方法 的不同做出不同的事情－－比如，代理可能会将POST请求直接发送给服务器，而将GET请求发送给另一个HTTP应用程序(比如web缓存)。TRACE并不提供区分这些方法的机制。通常，中间应用程序会自行决定对TRACE请求的处理方式。

TRACE请求中不能带有实体的主体部分。TRACE响应和实体主体部分包含了响应服务器收到的请求的精确副本。

### OPTIONS

OPTIONS方法请求web服务器告知其支持的各种功能。可以询问服务器通常支持哪些方法，或者对某些特殊资源支持哪些方法。(有些服务器可能只支持对一些特殊类型的对象使用特定的操作)。

这为客户端应用程序提供了一种手段，使其不用实际访问那些资源就能判定访问各种资源的最优方式。

### DELETE

顾名思义，DELETE方法所做的事情就是请服务器删除请求URL所指定的资源。但是，客户端应用程序无法保证删除操作一定会被执行。因为HTTP规范允许服务器在不通知客户端的情况下撤销请求。

### 扩展方法

HTTP被设计成字段可扩展的，这样新的特性就不会使老的软件失效了。扩展方法指的就是没有在HTTP／1.1规范中定义的方法。服务器会为它所管理的资源实现一些HTTP服务，这些方法为开发者提供了一种扩展这些HTTP服务能力的手段。下面列出了一些常见的扩展方法实例。这些方法就是WebDAV HTTP扩展包含的所有方法，这些方法有助于通过HTTP将Web内容发布到Web服务器上云。

方法 | 描述 
--- | ---
LOCK | 允许用户"锁定"资源---比如，可以在编辑某个资源的时候将其锁定，以防别人同时对其进行修改
MKCOL | 允许用户创建资源
COPY | 便于在服务器上复制资源
MOVE | 在服务器上移动资源

并不是所有的扩展方法都是在正式规范中定义的，认识到这一点很重要。如果你定义了一个扩展方法，很可能大部分HTTP应用程序都无法理解。同样，你的HTTP应用程序也可能会遇到一些其他应用程序在用的，而它并不理解的扩展方法。

在这些情况下，最好对扩展方法宽容一些。如果能够在不破坏端到端行为的情况下将带有未知方法的报文传递给下游服务器的话，代理会尝试着传递这些报文的。否则，它们会以501 Not Implemented(无法实现)状态码进行响应。最好按惯例"对所发送的内容要求严一点，对所接收的内容宽容一些"来处理扩展方法(以及一般的HTTP扩展)。


## 状态码

### 信息性状态码(100-199)

### 成功状态码(200-299)

客户端发起请求时，这些请求通常都是成功的。服务器有一组用来表示成功的状态码，分别对应于不同类型的请求。


### 重定向状态码(300-399)

**301的流量分析 **

当服务器返回301后，客户端会再向location里面的地址发送一次请求。

**304流量分析**

有的客户端应用程序会在请求头中添加一个字段 `If-Modified-Since: Fri, Oct 3 1997 02:16:00 GMT` ,这样就会返回一个304(Not Modified) 状态码。可以通过某些重定向状态码对资源的应用程序本地副本与源端服务器上的资源进行验证。

> 302、303、307状态码之间存在一些交叉，大部分差别都源于HTTP/1.0和HTTP/1.1应用程序对这些状态码处理方式的不同。如对于HTTP/1.1客户端，用307状态码取代302状态码来进行临时重定向。这样服务器就可以将302状态保留起来，为HTTP/1.0客户端使用了。这样一来，服务器要选择适当的重定向状态码放入重定向响应中发送，就需要查看客户端的HTTP版本了。

### 客户端错误状态码(400-499)

很多客户端错误都是由浏览器来处理的，甚至不会打扰到你。只有少量错误，比如404,还是会穿过浏览器来到用户面前。

状态码  | 原因短语 | 含义
--- | --- | ---
400 | Bad Request | 用于告知客户端它发送了一个错误的请求
401 | Unauthorized | 与适当的首部一同返回，在这些首部中请求客户端在获取对资源的访问权之前，对自己进行认证。
402 | Payment Required | 现在这个状态码还未使用，但已经被保留，以作未来之用
403 | Forbidden | 用于说明请求被服务器拒绝了。如果服务器想说明为什么拒绝请求，可以包含实体的主体部分来对原因进行描述，但这个状态码通常是在服务器不想说明拒绝原因的时候使用的。
404 | Not Found | 用于说明服务器无法找到所请求的URL。通常会包含一个实体，以便 客户端应用程序显示给客户看
405 | Method Not Allowed | 发起的请求中带有所请求的URL不支持的方法时，使用此状态码。应该在响应中包含Allow首部，以告知客户端对所请求的资源可以使用哪些方法。
406 | Not Acceptable | 客户端可以指定参数来说明它们愿意接收什么类型的实体。服务器没有与客户端可接受的URL相匹配的资源时，使用此代码。通常，服务器会包含一些首部，以便客户端弄清楚为什么请求无法满足。
407 | Proxy Authentication Required | 与401状态码类似，但用于要求对资源进行认证的代理服务器。
408 | Request Timeout | 如果客户端完成请求所花的时间太长，服务器可以回送此状态码，并关闭连接。超时时长随服务器的不同有所不同，但通常对所有的合法请求来说，都是够长的。
409 | Conflict | 用于说明请求可能在资源上引发的一些冲突。服务器担心请求会引发冲突时，可以发送此状态码。响应中应该包含描述冲突的主体。


### 服务器错误状态码(500-599)

有时客户端 发送了一条有效请求，服务器自身却出错了。这可能是客户端磁卡了服务器的缺陷，或者服务器上的子元素，比如某个网关资源，出了错。

代理尝试着代表客户端与服务器进行交流时，经常会出现错误。代理会发布5XX服务器错误状态码来描述所遇到的问题。

状态码 | 原因短语 | 含义
-- |
500 | Internal Server Error | 服务器遇到一个妨碍它为请求提供服务的错误时，使用此状态码
501 | Not Implemented | 客户端发起的请求超出服务器的能力范围(比如，使用了服务器不支持的请求方法)时，使用此状态码
502 | Bad Gateway | 作为代理或网关使用的服务器从请求响应链的下一条链路上收到了一条伪响应(比如，它无法连接到其父网关)时，使用此状态码
503 | Service Unavailable | 用来说明服务器现在无法为请求提供服务，但将来可以。如果服务器知道什么时候资源会变为可用的，可以在响应中包含一个Retry-After首部。
504| Gateway Timeout | 与状态码408类似，只是这里的响应来自一个网关或代理，它们在等待另一服务器对其请求进行响应时超时了。
505 | HTTP Version Not Supported | 服务器收到的请求使用了它无法或不愿支持的协议版本时，使用此状态码。有些服务器应用程序会选择不支持协议的早期版本

## 首部

首部和方法配合工作，共同决定了客户端和服务器能做什么事情。

在请求和响应报文中都可以用首部来提供信息，有些首部是某种报文专用的，有些首部则更通用一些。可以将首部分为五个主要的类型。

### 通用首部

这些是客户端和服务器都可以使用的通用首部。可以在客户端、服务器和其他应用程序之间提供一些非常有用的通用功能。比如，Date首部就是一个通用首部，每一端都可以用它来说明构建报文的时间和日期：

<pre>
Date: Tue, 3 Oct 1974 xx:xx:xx GMT
</pre>

首部 | 描述
--- | 
Transfer-Encoding | 告知接收端为了保证报文的可靠传输，对报文采用了什么编码方式
Update | 给出了发送端可能想要"升级"使用的新版本或协议
Via | 显示了报文经过的中间节点(代理、网关)


### 请求首部

从名字中就可以看出，请求首部是请求报文特有的。它们为服务器提供了一些额外信息，比如客户端希望接收什么类型的数据。例如，下面的Accept首部就用来告知服务器客户端会接受与其请求相符的任意媒体类型：

<pre>
Accept: */*
</pre>

服务器可以根据请求首部给出的客户端信息，试着为客户端提供更好的响应。

首部 | 描述
--- |
Client-IP | 提供了运行客户端的机器的IP地址
From | 提供了客户端用户的E-mail地址
Host | 给出了接收请求的服务器的主机名和端口号
Referer | 提供了包含当前请求URI的文档的URL,一般用来让服务器判断来源页面,也可用作防盗链
UA-Color | 提供了与客户端显示器的显示颜色有关的信息
UA－CPU | 提供了客户端CPU的类型或制造商
UA-OS | 给出了运行在客户端机器上的操作系统名称及版本
User-Agent | 将发起请求的应用程序名称告知服务器

**Accept首部**

Accept首部为客户端提供了一种将其喜好和能力告知服务器的方式，包括它们想要什么，可以使用什么，以及最重要的，它们不想要什么。这样，服务器就可以根据这些额外信息，对要发送的内容做出更明智的决定。对要发送的内容做出更明智的决定。Accept首部会使连接的两端都受益。客户端会得到它们想要的内容，服务器则不会浪费其时间和带宽来发送客户端无法使用的东西。如:Accept/Accept-Charset/Accept/Encoding/Accept-Language/TE

**条件请求首部**

有时客户端希望为请求加上某些限制。比如，如果客户端已经有了一份文档副本，就希望只在服务器上的文档与客户端拥有的副本有所区别时，才请求服务器传输文档。通过条件请求首部，客户端就可以为请求加上这种限制，要求服务器在对请求进行响应之前，确保某个条件为真。

首部 | 描述
--- |
Expect | 允许客户端列出某请求所要求的服务器行为
If-Match | 如果实体标记与文档当前的实体标记相匹配，就获取这份文档
If-Modified-Since | 除非在某个指定的日期之后资源被修改过，否则就限制这个请求
If-None-Match | 如果提供的实体标记与当前文档的实体标记不相符，就获取文档
If-Range | 允许对文档的某个范围进行条件请求
If-Unmodified-Since | 除非在某个指定日期之后资源没有被修改过，否则就限制这个请求
Range | 如果服务器支持范围请求，就请求资源的指定范围

**安全请求首部**

HTTP本身就支持一种简单的机制，可以对请求进行质询/响应认证。这种机制要求客户端在获取特定的资源之前，先对自身进行认证，这样就可以使事务稍微安全一些。

首部 | 描述
--- |
Authorization | 包含了客户端提供给服务器，以便对其自身进行认证的数据
Cookie | 客户端用它向服务器传送一个令牌－－它并不是真正的安全首部，但确实隐含了安全功能
Cookie2 | 用来说明请求端支持的cookie版本

**代理请求首部**

随着因特网上代理的普遍使用，人们定义了几个首部一协助其更好的工作。

首部 | 描述
--- |
Max-Forward | 在通往源端服务器的路径上，将请求转发给其他代理或网关的最大次数--与TRACE方法一同使用
Proxy-Authorization | 与Authorization首部相同，但这个首部是在与代理进行认证时使用的
Proxy-Connection | 与Connection首部相同，但这个首部在与代理建立连接时使用的






### 响应首部

响应报文有自己的首部集，以便为客户端提供信息(比如，客户端在与哪种类型的服务器进行交互)。例如，下列Server首部就用来告知客户端它在与一个版本1.0的Tiki-Hut服务器进行交互：

<pre>
Server: Tiki-Hut/1.0
</pre>

### 实体首部

实体首部指的是用于应对实体主体部分的首部。比如，可以用实体首部来说明实体主体部分的数据类型。例如，可以通过下列Content-Type首部告知应用程序，数据是以iso-latin-1字符集表示的HTML文档：

<pre>
Content-Type: text/html; charset=iso-latin-1
</pre>

### 扩展首部

扩展首部是非标准的首部，由应用程序开发者创建，但还未添加到已批准的HTTP规范中去。即使不知道这些扩展首部的含义，HTTP程序也要接受它们并对其进行转发。











