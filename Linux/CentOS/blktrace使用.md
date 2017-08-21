# [blktrace使用](http://linuxperf.com/?p=161)

<pre>
blktrace -d /dev/rbd0 -o -|blkparse -i - > rbd.out
head -n 3000 rbd.out |awk '{print $6}' |grep C |wc -l
head -n 3000 rbd.out |awk '{print $6}' |grep W |wc -l
head -n 3000 rbd.out |awk '{print $6}' |grep R |wc -l
head -n 3000 rbd.out |awk '{print $6}' |grep Q |wc -l
head -n 3000 rbd.out |awk '{print $6}' |grep G |wc -l
head -n 3000 rbd.out |awk '{print $6}' |grep I |wc -l
head -n 3000 rbd.out |awk '{print $6}' |grep U |wc -l
</pre>