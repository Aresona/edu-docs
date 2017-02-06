### Python简介
Python是一种新的脚本解释程序,是作为ABC语言的一种继承;一般在互联网公司用它来做: 自动化运维、自动化测试、大数据分析、爬虫、web等.
### Python和C的区别
C语言: 代码编译得到机器码,机器码在处理器上直接执行,每一条指令控制CPU工作 

其他语言: 代码编译得到字节码,虚拟机执行字节码并转换成机器码后在处理器上执行
### Python各类
* Cpython

	Python的官方版本，使用C语言实现，使用最为广泛，CPython实现会将源文件（py文件）转换成字节码文件（pyc文件），然后运行在Python虚拟机上。
* Jython

	Python的Java实现，Jython会将Python代码动态编译成Java字节码，然后在JVM上运行。
* IronPython

	Python的C#实现，IronPython将Python代码编译成C#字节码，然后在CLR上运行。（与Jython类似）
* Pypy(特殊)

	Python实现的Python，将Python的字节码字节码再编译成机器码。

	PyPy，在Python的基础上对Python的字节码进一步处理，从而提升执行速度！

### 内容编码

python解释器在加载.py文件中的代码时,会对内容进行编码(默认ascii),但是无法将世界上的各种文字和符号全部表示,所以,就需要新出一种可以代表所有字符和符号的编码,即:Unicode;

UTF-8是对Unicode编码的压缩和优化,他不再使用最少2个字节,而是把所有的字符和符号进行分类:ascii码中的内容用1个字节保存,东亚的字符用2个字节保存..

所以,python解释器在加载.py文件中的代码时,会对内容进行编码,如果我们有中文的话就需要指定默认编码 
<pre>
#!/usr/bin/env python
# -*- coding: utf-8 -*-
print "你好,世界"
</pre>

# 变量

可以把变量看成是一个存储信息的容器，它的唯一目的是把数据存储或者标记到内存中。

<pre>
Variables are used to store information to be referenced and manipulated in a computer program. They also provide a way of labeling data with a descriptive name, so our programs can be understood more clearly by the reader and ourselves. It is helpful to think of variables as containers that hold information. Their sole purpose is to label and store data in memory. This data can then be used throughout your program.
</pre>

1. python是一个动态语言，不需要在声明变量的时候指定数据类型
2. 其实python里面是没有赋值这个概念的，它其实是引用，[可以参考](https://my.oschina.net/leejun2005/blog/145911)
3. 复杂变量的写法：驼峰和下滑线

## 变量定义的规则

* 变量名只能是字母、数字、或下划线的任意组合
* 变量名的第一个字符不能是数字
* 变量不能是关键字 ['and', 'as', 'assert', 'break', 'class', 'continue', 'def', 'del', 'elif', 'else', 'except', 'exec', 'finally', 'for', 'from', 'global', 'if', 'import', 'in', 'is', 'lambda', 'not', 'or', 'pass', 'print', 'raise', 'return', 'try', 'while', 'with', 'yield']

另外变量还有一些大家都遵守的潜规则，也就是需要有注释


## 常量

在python中是没有常量这个概念的，我们一般使用大写字母来表示常量，但是它还是能改的，只是不应该改。如

<pre>
PIE = "3.1435436..."
</pre>


## 字符编码

计算机底层只认识0和1,电路最底层只有两种状态，一种是通电，一种是不通电，也就是只有两种状态；如果是这样的话，那么计算机怎么显示字母呢？



python解释器在加载 .py 文件中的代码时，会对内容进行编码（默认ascill）

ASCII（American Standard Code for Information Interchange，美国标准信息交换代码）是基于拉丁字母的一套电脑编码系统，主要用于显示现代英语和其他西欧语言，其最多只能用 8 位来表示（一个字节），即：2**8 = 256-1，所以，ASCII码最多只能表示 255 个符号。

### 两条线之中文线
<pre>
Ascii  --->   GB2312   --->   GBK   --->   GB18030   
</pre>

> windows的缺少内码还是GBK，可以通过GB18030升级包到GB18030，但GBK对于一般的人员已经足够了。


### 两条线之ALL

显然ASCII码无法将世界上的各种文字和符号全部表示，所以就需要一种可以代表所有字符和符号的编码，即Unicode。

<pre>
ASCII   --->   Unicode   --->   UTF-8
</pre>

Unicode（统一码、万国码、单一码）是一种在计算机上使用的字符编码。Unicode 是为了解决传统的字符编码方案的局限而产生的，它为每种语言中的每个字符设定了统一并且唯一的二进制编码，规定虽有的字符和符号最少由 16 位来表示（2个字节），即：2 **16 = 65536，

注：此处说的的是最少2个字节，可能更多

UTF-8，是对Unicode编码的压缩和优化，他不再使用最少使用2个字节，而是将所有的字符和符号进行分类：ascii码中的内容用1个字节保存、欧洲的字符用2个字节保存，东亚的字符用3个字节保存...;另外unicode和GBK并不能很好的兼容。

告诉解释器使用哪个编码

<pre>
# -*- coding: utf-8 -*-
</pre>

> 默认python3用的是UTF-8编码格式，而pyton2里面用的是ASCII。


## 注释

单行用#，多行用''''''(可以是单引号和双引号);另外 `'''`除了可以注释之外，还可以打印多行，只要是多行都需要用这个，而如果是单行的话，单个单引号和双引号就可以表示；如

<pre>
msg = '''GfOfOldboy
hehe'''
print(msg)
</pre>

## 用户输入

<pre>
username = input("username:")
password = input("password:")
print(username,password)
</pre>

## 变量引用

<pre>
info = '''
------------- info of %s ------
Name:%s
Age:%s
Job:%s
Salary:%s
'''%(username,username,age,job,salary)
print(info)
</pre>

<pre>
info2 = '''
------------- info of {_name} ------
Name:{_name}
Age:{_age}
Job:{_job}
Salary:{_salary}
'''.format(_name=name,
           _age=age,
           _job=job,
           _salary=salary)
</pre>

<pre>
info3 = '''
------------- info of {0} ------
Name:{0}
Age:{1}
Job:{2}
Salary:{3}
'''.format(name,age,job,salary)
</pre>

`%s` 代表的是string,还可以接受 `%d`、`%f`等,也就是说只能接受数字了，它跟 `%s` 的区别是帮助检测验证数据类型。

<pre>
print(type(age))
age = int(input("age:"))
print(type(age),type(str(age)))
</pre>

## 初识模块

<pre>
import getpass
username = input("username:")
password = getpass.getpass("password:")
print(username,password)
</pre>

> 这个功能在pycharm下看不出效果来，但在bash下面可以看出来

## 逻辑判断

<pre>
if _username == username and _password == password:
    print("Welcom user {name} login...".format(name=username))
else:
    print("Invalid username or password!")
</pre>

> python里面是强制缩进，这样就会省掉一些结束符，并且结构更清晰。

## 循环
`while` 循环
<pre>
age_of_oldboy = 56
count = 0
while count < 3:
    guess_age = int(input("Guess Age:"))
    if guess_age == age_of_oldboy:
        print("yes,you got it!")
        break
    elif guess_age > age_of_oldboy:
        print("think smaller....")
    else:
        print("think bigger!")
    count += 1
else:
        print("you have tried too many times..fuck off")
</pre>
`for` 循环
<pre>
for i in range(10):
    print("loop",i)
for i in range(10):
    print("loop",i)
age_of_oldboy = 56
count = 0
for i in range(3):
    guess_age = int(input("Guess Age:"))
    if guess_age == age_of_oldboy:
        print("yes,you got it!")
        break
    elif guess_age > age_of_oldboy:
        print("think smaller....")
    else:
        print("think bigger!")
    count += 1
else:
        print("you have tried too many times..fuck off")
</pre>
### break和continue

continue是跳出本次循环，进入下次循环，而break是结束整个循环



# Tips
1. python3可以直接在里面写中文了,另外python3更规范了。
2. [官方文档](http://www.cnblogs.com/alex3714/articles/54565198.html)
3. 异步牛逼之处在于单线程下比多线程下还快，目前还不支持python3.x,twisted
4. C不具备面向对象，而C++是面向对象的，并且加了一些其他的库
5. java是纯面向对象的语言，你就是写一句代码也要先把类定义好
6. ruby也是一个非常优秀的语言，只是在国内用的不太火
7. pycharm可以做补全，调试，开发效率高，不用vim的原因


# 作业　
## 作业一

1. 输入用户名密码
2. 认证成功后显示欢迎信息
3. 输错三次后锁定
4. 如果下次执行的时候还是这个用户名的话提示已被锁定（信息需要存在list里面），不能用到任何shell命令的东西，只能用python自带的文件调用接口。

## 作业二：

1. 三级菜单(返回上一级，在任一级可以直接退出程序)　
2. 可依次选择进入各子菜单
3. 所需要新知识：列表、字典

