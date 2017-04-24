# MySQL引擎

InnoDB as Default Storage Engine
从mysql-5.5.5开始,InnoDB作为默认存储引擎，InnoDB作为支持事务的存储引擎，拥有相关的RDBMS特性：包括ACID事务支持，参考完整性（外健），灾难恢复能力等特性。

同时作为维护mysql内部结构的mysql和information_schema两个databases中的表，依然使用MyISAM存储引擎，而且不能被更改为InnoDB.

## InnoDB table优点

- 硬件故障导致的server crash（比如停电），在下次重起database会自动恢复。
- 由InnoDB buffer pool 负责cache被访问的表和索引数据，直接在内存中进行处理，根据合理算法来保持热点块（hot）保留在内存中，极大地提高访问效率，减少I/O。
- 使用外健来实现参考完整性，实现数据的逻辑分割，同时还可以实现关联更新。
- 如果数据损坏，checksum机制能够在你使用时候提醒你这些受损的数据。
- 建议所有的表都有主健（频繁使用的field上或者auto_increment field上创建），这将极大提高基于where条件为主健（primary key）上的查询性能，包括order by , group by 等。
- 提供change buffering自动优化机制来优化诸如Insert,Update,Delete等操作；InnoDb能允许同一表上的读，写操作，还能cache 改变数据来减少I/O.

## InnoDB table最佳处理方法

- 给每个InnoDB表指定主健
- 为提高组合查询性能，定义外健在join columns上，并且定义为相同数据类型，外健能实现因主表更新而关联更新子表，并且阻止子表的插入新数据，当这些新数据并不在主表存在时。
- 改变autocommit默认方式为不自动提交，减少提交次数过多带来的性能影响；可以由start transaction and commit来以"逻辑事务处理"等为单位来控制提交次数。
- 停止使用lock table语句，InnoDB能处理同一表上的读写并发sessions,并且不存在可靠性和性能损失。
- Enable innodb_file_per_table开关，分开表空间存放数据，避免巨型系统表空间出现；同时为诸如压缩和fast truncate 等操作提供基础。
- 根据应用实际情况，进行表压缩，这不会影响该表的读写能力。
- 如果建表时指定engine= 子句存在问题，使用-sql_mode=no_engine_substitution来阻止表以其它存储引擎创建。

## 验证InnoDB在系统的状态
  
使用命令 `SHOW VARIABLES LIKE 'have_innodb';` 如果是NO,表示没有支持InnoDB,如果是DISABLED，则看是否配置中有skip-innodb选项，需要去掉。如果支持如下

<pre>
MariaDB [(none)]> show variables like 'have_innodb';
+---------------+-------+
| Variable_name | Value |
+---------------+-------+
| have_innodb   | YES   |
+---------------+-------+
1 row in set (0.06 sec)
</pre>
使用命令SHOW ENGINES；能看到不同存储引擎，如果DEFAULT在innodb，代表支持并且为默认存储引擎。

<pre>
MariaDB [(none)]> show engines;
+--------------------+---------+----------------------------------------------------------------------------+--------------+------+------------+
| Engine             | Support | Comment                                                                    | Transactions | XA   | Savepoints |
+--------------------+---------+----------------------------------------------------------------------------+--------------+------+------------+
| CSV                | YES     | CSV storage engine                                                         | NO           | NO   | NO         |
| MRG_MYISAM         | YES     | Collection of identical MyISAM tables                                      | NO           | NO   | NO         |
| MEMORY             | YES     | Hash based, stored in memory, useful for temporary tables                  | NO           | NO   | NO         |
| BLACKHOLE          | YES     | /dev/null storage engine (anything you write to it disappears)             | NO           | NO   | NO         |
| MyISAM             | YES     | MyISAM storage engine                                                      | NO           | NO   | NO         |
| InnoDB             | DEFAULT | Percona-XtraDB, Supports transactions, row-level locking, and foreign keys | YES          | YES  | YES        |
| ARCHIVE            | YES     | Archive storage engine                                                     | NO           | NO   | NO         |
| FEDERATED          | YES     | FederatedX pluggable storage engine                                        | YES          | NO   | YES        |
| PERFORMANCE_SCHEMA | YES     | Performance Schema                                                         | NO           | NO   | NO         |
| Aria               | YES     | Crash-safe tables with MyISAM heritage                                     | NO           | NO   | NO         |
+--------------------+---------+----------------------------------------------------------------------------+--------------+------+------------+

</pre>

## MyISAM与Innodb的区别

基本的差别为：MyISAM类型不支持事务处理等高级处理，而InnoDB类型支持。MyISAM类型的表强调的是性能，其执行数度比InnoDB类型更快，但是不提供事务支持，而InnoDB提供事务支持以及外部键等高级数据库功能。

### 一些细节和具体实现的差别：

- InnoDB 中不保存表的具体行数，也就是说，执行select count(*) from table时，InnoDB要扫描一遍整个表来计算有多少行，但是MyISAM只要简单的读出保存好的行数即可。注意的是，当count(*)语句包含 where条件时，两种表的操作是一样的。
- MyISAM只支持表级锁，用户在操作myisam表时，select，update，delete，insert语句都会给表自动加锁，如果加锁以后的表满足insert并发的情况下，可以在表的尾部插入新的数据。InnoDB支持事务和行级锁，是innodb的最大特色。行锁大幅度提高了多用户并发操作的新能。但是InnoDB的行锁，只是在WHERE的主键是有效的，非主键的WHERE都会锁全表的。


# [MySQL数据库备份和恢复方法详解](http://www.ha97.com/4045.html)

目前 MySQL 支持的免费备份工具有：mysqldump、mysqlhotcopy，还可以用 SQL 语法进行备份：BACKUP TABLE 或者 SELECT INTO OUTFILE，又或者备份二进制日志（binlog），还可以是直接拷贝数据文件和相关的配置文件。MyISAM 表是保存成文件的形式，因此相对比较容易备份，上面提到的几种方法都可以使用。Innodb 所有的表都保存在同一个数据文件 ibdata1 中（也可能是多个文件，或者是独立的表空间文件），相对来说比较不好备份，免费的方案可以是拷贝数据文件、备份 binlog，或者用 mysqldump。

## mysqldump备份

mysqldump 是采用SQL级别的备份机制，它将数据表导成 SQL 脚本文件，在不同的 MySQL 版本之间升级时相对比较合适，这也是最常用的备份方法。

## mysqlhotcopy备份

mysqlhotcopy 是一个 PERL 程序，最初由Tim Bunce编写。它使用 LOCK TABLES、FLUSH TABLES 和 cp 或 scp 来快速备份数据库。它是备份数据库或单个表的最快的途径，但它只能运行在数据库文件（包括数据表定义文件、数据文件、索引文件）所在的机器上。mysqlhotcopy 只能用于备份 MyISAM，并且只能运行在类Unix 和 NetWare 系统上。

## SQL请求备份

BACKUP TABLE 语法其实和 mysqlhotcopy 的工作原理差不多，都是锁表，然后拷贝数据文件。它能实现在线备份，但是效果不理想，因此不推荐使用。它只拷贝表结构文件和数据文件，不同时拷贝索引文件，因此恢复时比较慢。

例：
<pre>
BACK TABLE tbl_name TO '/tmp/db_name/';
</pre>

注意，必须要有 FILE 权限才能执行本SQL，并且目录 /tmp/db_name/ 必须能被 mysqld 用户可写，导出的文件不能覆盖已经存在的文件，以避免安全问题。

`SELECT INTO OUTFILE` 则是把数据导出来成为普通的文本文件，可以自定义字段间隔的方式，方便处理这些数据。

<pre>
SELECT * INTO OUTFILE '/tmp/db_name/tbl_name.txt' FROM tbl_name;
</pre>

注意，必须要有 FILE 权限才能执行本SQL，并且文件 `/tmp/db_name/tbl_name.txt` 必须能被 mysqld 用户可写，导出的文件不能覆盖已经存在的文件，以避免安全问题。

### 恢复
用 BACKUP TABLE 方法备份出来的文件，可以运行 RESTORE TABLE 语句来恢复数据表。
<pre>
RESTORE TABLE FROM '/tmp/db_name/';
</pre>
用 SELECT INTO OUTFILE 方法备份出来的文件，可以运行 LOAD DATA INFILE 语句来恢复数据表。
<pre>
LOAD DATA INFILE '/tmp/db_name/tbl_name.txt' INTO TABLE tbl_name;
</pre>
权限要求类似上面所述。倒入数据之前，数据表要已经存在才行。如果担心数据会发生重复，可以增加 REPLACE 关键字来替换已有记录或者用 IGNORE 关键字来忽略他们。

## 二进制日志(binlog)

采用 binlog 的方法相对来说更灵活，省心省力，而且还可以支持增量备份。

<pre>
server-id = 1
log-bin = binlog
log-bin-index = binlog.index
</pre>
然后启动 mysqld 就可以了。运行过程中会产生 binlog.000001 以及 binlog.index，前面的文件是 mysqld 记录所有对数据的更新操作，后面的文件则是所有binlog 的索引，都不能轻易删除。

需要备份时，可以先执行一下 SQL 语句，让 mysqld 终止对当前 binlog 的写入，就可以把文件直接备份，这样的话就能达到增量备份的目的了：
<pre>
FLUSH LOGS;
</pre>

如果是备份复制系统中的从服务器，还应该备份 `master.info` 和 `relay-log.info` 文件。

备份出来的 binlog 文件可以用 MySQL 提供的工具 mysqlbinlog 来查看，如：
<pre>
/usr/local/mysql/bin/mysqlbinlog /tmp/binlog.000001</pre>

该工具允许你显示指定的数据库下的所有 SQL 语句，并且还可以限定时间范围，相当的方便，详细的请查看手册。

恢复时，可以采用类似以下语句来做到：
</pre>
/usr/local/mysql/bin/mysqlbinlog /tmp/binlog.000001 | mysql -uyejr -pyejr db_name</pre>

把 mysqlbinlog 输出的 SQL 语句直接作为输入来执行它。

如果你有空闲的机器，不妨采用这种方式来备份。由于作为 slave 的机器性能要求相对不是那么高，因此成本低，用低成本就能实现增量备份而且还能分担一部分数据查询压力，何乐而不为呢？

## 直接备份数据文件

相较前几种方法，备份数据文件最为直接、快速、方便，缺点是基本上不能实现增量备份。为了保证数据的一致性，需要在拷贝文件前，执行以下 SQL 语句：

<pre>FLUSH TABLES WITH READ LOCK;</pre>

也就是把内存中的数据都刷新到磁盘中，同时锁定数据表，以保证拷贝过程中不会有新的数据写入。这种方法备份出来的数据恢复也很简单，直接拷贝回原来的数据库目录下即可。

注意，对于 Innodb 类型表来说，还需要备份其日志文件，即 `ib_logfile*` 文件。因为当 Innodb 表损坏时，就可以依靠这些日志文件来恢复。

## 备份策略

对于中等级别业务量的系统来说，备份策略可以这么定：第一次全量备份，每天一次增量备份，每周再做一次全量备份，如此一直重复。而对于重要的且繁忙的系统来说，则可能需要每天一次全量备份，每小时一次增量备份，甚至更频繁。为了不影响线上业务，实现在线备份，并且能增量备份，最好的办法就是采用主从复制机制(`replication`)，在 `slave` 机器上做备份。

## 数据维护和灾难恢复

作为一名DBA(我目前还不是，呵呵)，最重要的工作内容之一是保证数据表能安全、稳定、高速使用。因此，需要定期维护你的数据表。以下 SQL 语句就很有用：
<pre>
CHECK TABLE 或 REPAIR TABLE，检查或维护 MyISAM 表
OPTIMIZE TABLE，优化 MyISAM 表
ANALYZE TABLE，分析 MyISAM 表
</pre>
当然了，上面这些命令起始都可以通过工具 myisamchk 来完成，在这里不作详述。

Innodb 表则可以通过执行以下语句来整理碎片，提高索引速度：

<pre>ALTER TABLE tbl_name ENGINE = Innodb;</pre>
这其实是一个 NULL 操作，表面上看什么也不做，实际上重新整理碎片了。

通常使用的 MyISAM 表可以用上面提到的恢复方法来完成。如果是索引坏了，可以用 `myisamchk` 工具来重建索引。而对于 `Innodb` 表来说，就没这么直接了，因为它把所有的表都保存在一个表空间了。不过 `Innodb` 有一个检查机制叫 `模糊检查点`，只要保存了日志文件，就能根据日志文件来修复错误。可以在 my.cnf 文件中，增加以下参数，让 mysqld 在启动时自动检查日志文件：
<pre>
innodb_force_recovery	= 4
</pre>
关于该参数的信息请查看手册。


[51CTO参赛文章](http://laoguang.blog.51cto.com/6013350/1078820)