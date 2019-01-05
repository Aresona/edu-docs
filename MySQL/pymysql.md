# [pymysql 模块学习](https://www.python.org/dev/peps/pep-0249/)

## 模块接口

数据库的访问是通过一个 `connection objects` 来实现的。

### Connection
Connection objects should respond to the follwing methods.

#### Connection methods

function | notes
--- | ---
.close() | 如果未 commit 会导致 roll back
. commit() | Commit any pending transaction to the database.
.rollback() | 可选，需要支持事务；会触发数据库 roll back to the start of any pending transaction.
.cursor() | 返回一个新的 Cursor Object

#### Cursor Objects
Cursor objects represent a database cursor, whitch is used to manage the context of a fetch operation. 从同一个连接生成的 cursor 不是孤立的，它们之间的操作相互可见。而不同连接产生的 cursor 可能是孤立的，取决于事务的支持。

Cursor Objects should respond to the follwing methods and atrributes.

**属性**

**.description**

read-only, is a sequence of 7-item sequences.[name, type_code, display_size, internal_size, precision, scale, null_ok]

前两个元素是强制性的，剩余的是可选的，并且默认是 None, 另外，如果未查询或查询未返回行时，该属性是 None

**.rowcount**

read-only, 影响的行数，如果没有执行或者识别失败时会返回 -1。

**Cursor methods**

function | notes
---- | ----
.callproc(procname [,parameters]) | 调用存储过程
.close() | 关闭 cursor
.execute(operation [,parameters]) | Prepare and execute a database operation,可能通过一个元组来执行多行，但是已经过时，可以通过 executemany()来实现.
.executemany(operation [,parameters]) | 其实也是通过执行多次 execute()或者通过元组的形式调用一次 execute()来完成。
.fetchone() | 获取结果集的下一行，返回一个单独的语句或 None。如果查询未产生结果集时会报异常
.fetchmany([size=cursor.arraysize]) | 获取查询集的下一个行集，形式为一个嵌套列表，当没有更多内容时，返回空列表。每次返回的行数用size来定义
.fetchall() | 获取结果集中的全部行数，用嵌套列表来表示。


## [pymysql 使用方法](http://www.runoob.com/python3/python3-mysql.html)

**总结**

> pymysql 通过 connection 来生成 cursor 对象，而 cursor 对象通过 fetchone(),commit(),execute() 等方法来实现数据库操作。