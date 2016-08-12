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