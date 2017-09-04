# SAR使用

<pre>
sar -n DEV 1 -o /root/sar1.out &> /dev/null
sar -n DEV -f /root/sar1.out |less
sar -n DEV -f /root/sar.out |egrep "ens4f0|ens5f0" > 1
awk '$6>200000.00{print;}' 1 > 2
awk '$7>200000.00{print;}' 1 > 3
</pre>

## 查看CPU使用率
<pre>
sar
sar 1 3
</pre>
<pre>
[root@host71 ~]# sar 1 3
Linux 3.10.0-327.36.1.el7.x86_64 (host71) 	08/23/2017 	_x86_64_	(40 CPU)

09:30:26 AM     CPU     %user     %nice   %system   %iowait    %steal     %idle
09:30:27 AM     all      0.03      0.00      0.10      0.05      0.00     99.82
09:30:28 AM     all      0.08      0.00      0.08      0.00      0.00     99.85
09:30:29 AM     all      0.03      0.00      0.13      0.00      0.00     99.85
Average:        all      0.04      0.00      0.10      0.02      0.00     99.84
</pre>
* %user 用户模式下消耗的CPU时间的比例；
* %nice 通过nice改变了进程调度优先级的进程，在用户模式下消耗的CPU时间的比例
* %system 系统模式下消耗的CPU时间的比例；
* %iowait CPU等待磁盘I/O导致空闲状态消耗的时间比例；
* %steal 利用Xen等操作系统虚拟化技术，等待其它虚拟CPU计算占用的时间比例；
* %idle CPU空闲时间比例；

## 查看平均负载
<pre>
sar -q
</pre>
指定 -q 后，就能查看运行队列中的进程数、系统上的进程大小、平均负载等；与其它命令相比，它能查看各项指标随时间变化的情况：

<pre>
[root@host71 ~]# sar -q 1 3
Linux 3.10.0-327.36.1.el7.x86_64 (host71) 	08/23/2017 	_x86_64_	(40 CPU)

09:33:06 AM   runq-sz  plist-sz   ldavg-1   ldavg-5  ldavg-15   blocked
09:33:07 AM         0      1327      0.00      0.02      0.05         0
09:33:08 AM         0      1327      0.00      0.02      0.05         0
09:33:09 AM         0      1327      0.00      0.02      0.05         0
Average:            0      1327      0.00      0.02      0.05         0
</pre>
* runq-sz：运行队列的长度（等待运行的进程数）
* plist-sz：进程列表中进程（processes）和线程（threads）的数量
* ldavg-1：最后1分钟的系统平均负载 ldavg-5：过去5分钟的系统平均负载
* ldavg-15：过去15分钟的系统平均负载
* blocked: 等待IO完成的task数

## 查看内存使用状况

<pre>
[root@host71 ~]# sar -r 1 3
Linux 3.10.0-327.36.1.el7.x86_64 (host71) 	08/23/2017 	_x86_64_	(40 CPU)

09:36:24 AM kbmemfree kbmemused  %memused kbbuffers  kbcached  kbcommit   %commit  kbactive   kbinact   kbdirty
09:36:25 AM  48523736  16572552     25.46     46952   7589044  21268804     32.67   9245188   5405484         0
09:36:26 AM  48523708  16572580     25.46     46960   7589036  21268804     32.67   9249276   5405484         0
09:36:27 AM  48523928  16572360     25.46     46960   7589044  21268804     32.67   9257472   5405484        20
Average:     48523791  16572497     25.46     46957   7589041  21268804     32.67   9250645   5405484         7
</pre>
* kbmemfree：这个值和free命令中的free值基本一致,所以它不包括buffer和cache的空间.
* kbmemused：这个值和free命令中的used值基本一致,所以它包括buffer和cache的空间.
* %memused：物理内存使用率，这个值是kbmemused和内存总量(不包括swap)的一个百分比.
* kbbuffers和kbcached：这两个值就是free命令中的buffer和cache.
* kbcommit：保证当前系统所需要的内存,即为了确保不溢出而需要的内存(RAM+swap).
* %commit：这个值是kbcommit与内存总量(包括swap)的一个百分比.

## 查看页面交换发生状况
<pre>
[root@host71 ~]# sar -W 1 3
Linux 3.10.0-327.36.1.el7.x86_64 (host71) 	08/23/2017 	_x86_64_	(40 CPU)

09:38:53 AM  pswpin/s pswpout/s
09:38:54 AM      0.00      0.00
09:38:55 AM      0.00      0.00
09:38:56 AM      0.00      0.00
Average:         0.00      0.00
</pre>
* pswpin/s：每秒系统换入的交换页面（swap page）数量
* pswpout/s：每秒系统换出的交换页面（swap page）数量

要判断系统瓶颈问题，有时需几个 sar 命令选项结合起来；

* 怀疑CPU存在瓶颈，可用 sar -u 和 sar -q 等来查看
* 怀疑内存存在瓶颈，可用sar -B、sar -r 和 sar -W 等来查看
* 怀疑I/O存在瓶颈，可用 sar -b、sar -u 和 sar -d 等来查看

> -b   report I/O and transter rate statistics

> -B   report paging statistics
> 
> -u   report CPU utilization
> 
> -d   监控磁盘活动


## 监视磁盘活动
同时，对磁盘活动也进行了监视。高磁盘使用率意味着，从磁盘请求数据的应用程序更有可能会被阻塞（暂停），直到磁盘为该进程做好准备。通常，解决方案涉及到将文件系统拆分到不同的磁盘或阵列。然而，第一步是要知道出现了问题。

sar -d 的输出显示了一个度量时间段内各种与磁盘相关的统计数据。为了更加简洁，显示了硬盘驱动器的活动。 

sar -d 的输出（显示了磁盘活动）
<pre>
$ sar -d 1 1
Average:          DEV       tps  rd_sec/s  wr_sec/s  avgrq-sz  avgqu-sz     await     svctm     %util
Average:       dev8-0      0.20      5.04      1.22     31.06      0.00     16.70      4.89      0.10
Average:      dev8-64      0.11      0.00      1.06      9.87      0.00     26.15     12.58      0.13
Average:      dev8-48      0.00      0.00      0.00      0.00      0.00      0.00      0.00      0.00
Average:      dev8-80      0.06      0.00      0.64     10.61      0.00     32.92     13.42      0.08
Average:      dev8-96      0.12      0.00      1.26     10.48      0.00     23.76     13.19      0.16
Average:     dev8-112      0.07      0.00      0.60      8.03      0.00     22.39     13.83      0.10
Average:     dev8-128      0.09      0.00      0.97     11.38      0.00     24.38     13.14      0.11
Average:     dev8-144      0.00      0.00      0.00      0.00      0.00      0.00      0.00      0.00
Average:     dev8-176      0.00      0.00      0.00      0.00      0.00      0.00      0.00      0.00
Average:     dev8-160      0.02      0.00      0.45     23.55      0.00      0.08      0.05      0.00
Average:     dev8-192      0.00      0.00      0.00      0.00      0.00      0.00      0.00      0.00
Average:      dev8-32      0.16      0.00      2.22     14.04      0.00     26.55     12.01      0.19
Average:      dev8-16      0.02      0.00      0.16      7.51      0.00     22.04     14.29      0.03
Average:     dev259-0      0.32      0.00      3.39     10.66      0.00      0.03      0.03      0.00
Average:     dev253-0      0.26      5.04      1.22     24.36      0.00     19.26      3.83      0.10
Average:     dev253-1      0.00      0.00      0.00      0.00      0.00      0.00      0.00      0.00
</pre>
和前面的示例一样，最左边的是时间。其他列如下：

* device： 这是指正在进行测量的磁盘或磁盘分区。在 Sun Solaris 中，必须通过查找 /etc/path_to_inst 中所报告的名称将该磁盘转换为物理磁盘，然后将该信息交叉引用到 /dev/dsk 中的项目。在 Linux® 中，使用了磁盘设备的主从设备号。
* %busy： 这是读取或写入设备的时间的百分比。
* avque： 这是用来串行化磁盘活动的队列的平均深度。avque 的值越大，发生的阻塞就越多。
* r+w/s、blks/s：这分别是用每秒的读或写操作和磁盘盘块来表示的磁盘活动。
* avwait：这是磁盘读或写操作等待执行的平均时间（单位为毫秒）。
* avserv：这是磁盘读或写操作所执行的平均时间（单位为毫秒）。
* rd_sec/s: 读取的扇区(sectors)数，每个sector是512字节
* tps: 对应的是IOPS
* avgrq-sz: issue to device的平均请求大小
* avgqu-sz: 请求的平均队列长度
* await: 一个IO请求花费的时间(单位为毫秒)，包括在队列中的时间
* svctm: 一个请求的service时间，与time in queue一起，组成await,但不具备价值
* %util: 设备饱和度，表示I/O请求所耗费的时间百分比(带宽利用率)

## 查看网络情况：

<pre>
n { keyword [,...] | ALL }
</pre>
这里的keyword包括：`DEV, EDEV, NFS, NFSD, SOCK, IP, EIP, ICMP, EICMP, TCP, ETCP, UDP, SOCK6, IP6, EIP6, ICMP6, EICMP6 and UDP6.`

* DEV 表示网络设备
* EDEV 表示网络设备的出错信息
* SOCK 表示IPV4下的socket in use
* IP 表示IPV4下的网络流量
* ICMP 表示ICMPV4下的网络流量
* TCP 表示TCPv4下的网络流量


# [kSar](http://www.dell.com/support/article/cn/zh/cndhs1/sln285492/how-to-use-ksar-to-visualize-performance-graphs?lang=en)