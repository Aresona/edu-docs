# Nginx_Rewrite
### rewrite命令
<pre>
rewrite 正则表达式 替换目标  flag标记
</pre>
flag标记可以用以下几种格式：
last   基本上都用这个FLAG
break 	中止rewrite,不再继续匹配
redirect	返回临时重定向的HTTP状态302
permanent	返回永久重定向的HTTP状态301

* 没有flag的rewrite指令完成location改写之后，继续往下寻找其他 `rewrite` 规则，看看有没有符合要求的。如果没有，那么进入 `location` 匹配。
* 带 `break` ,跳过其他所有 `rewrite` 规则，进入 `location` 匹配

> 以上说的 `rewrite` 规则属于 `nginx` 的内部重定向规则，也就是说，用户外部看到的url依然是他输入的url,而转让给后端应用的 `$uri`,则已经是nginx改写之后的结果。

> 如果需要进行显式地外部重定向，需要借助 `redirect`,`permanent` 这两个flag进行302和301重定向，它的行为和 `break`类似，区别于nginx会中断流程，通过http请求告诉客户端进行重定向，也就是这次请求不需要经过后端服务，由nginx全职负责。

### `last`和 `break`的区别

* last: last跳出location块，重新进行 `location` 匹配
* break跳过location下的后续rewrite规则，执行其他指令。

> 两者的本质区别在于是否**重新**进行 `location` 匹配，所以当在 `location` 上下文进行 `last rewrite` 时。对于不熟悉的rewrite指定的其他人容易造成误解。

### return 指令的应用
在 `rewrite` 模块中，有一条非常有用的指令 `return` ，用于直接返回客户端指定的状态码。基于支持指定文本内容和url，相比起使用`rewrite`指令 302 进行曲线救国，要简便的多。

<pre>
location = /index.php {
  if ( $arg_q = "" ) {
    return 302 /page_not_found.html;
  }

  if ( $arg_id = "" ) {
    return 404 "page not found";
  }
  return 200 "hello";
}
</pre>
### nginx重定向的IF条件判断
在server和location的两种情况下可以使用nginx的IF条件判断，条件可以为以下几种：

**匹配判断**

* ~为区分大小写匹配；
* !~为区分大小写不匹配；
* ~* 为不区分大小写匹配；
* !~* 为不区分大小写不匹配

<pre>
if ($http_user_agent ~ MSIE) {
	rewrite ^(.*)$ /nginx-ie/$1 break;
}
</pre>
**文件和目录判断**

* `-f` 和 `! -f`判断是否存在文件
* `-d` 和 `! -d`判断是否存在目录
* `-e` 和 `! -e`判断是否存在文件或目录
* `-x` 和 `! -x`判断是否可执行

<pre>
if (!-e $request_filename) {
	proxy_pass http://127.0.0.1;
}
</pre>
**return**
返回http代码，例如登录nginx防盗链
 