# Object

## request

request 对象用来存储客户发起的请求，但在 flask 中它怎么实现全局对象及线程安全？

>答案是 context locals

## 全局对象

> 在 flask 中，全局对象实际上是特定上下文本地对象的代理





### Application Object

The flask object implements a WSGI application and acts as the central object. It is passed the name of the module or package of the application. Once it is created it will act as a central registry for the view functions, the URL rules, template configuration and much more.

### Blueprint Objects

The basic concept of blueprints is that they record operations to execute when registered on an application. Flask associates view functions with blueprints when dispatching requests and generating URLs from one endpoint to another.



* AppContext
* Blueprint Objects
* Response Objects
* URL Route Registerations
* Thread Locals
* 