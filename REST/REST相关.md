# [深入浅出REST](http://www.infoq.com/cn/articles/rest-introduction)
## REST关键原则
REST定义了应该如何正确地使用（这和大多数人的实际使用方式有很大不同）Web标准，例如HTTP和URI。如果你在设计应用程序时能坚持REST原则，那就预示着你将会得到一个使用了优质Web架构（这将让你受益）的系统。总之，五条关键原则列举如下：

* 为所有“事物”定义ID
* 将所有事物链接在一起
* 使用标准方法
* 资源多重表述
* 无状态通信

> REST一种万维网软件架构风格。需要注意的是，REST是设计风格而不是标准。REST通常基于使用HTTP，URI，和XML以及HTML这些现有的广泛流行的协议和标准。

## 应用于WEB服务
符合REST设计风格的Web API称为RESTful API。它从以下三个方面资源进行定义：

* 直观简短的资源地址：URI，比如：http://example.com/resources/。
* 传输的资源：Web服务接受与返回的互联网媒体类型，比如：JSON，XML，YAML等。
* 对资源的操作：Web服务在该资源上所支持的一系列请求方法（比如：POST，GET，PUT或DELETE）。

