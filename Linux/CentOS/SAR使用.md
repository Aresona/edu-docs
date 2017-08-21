# SAR使用

<pre>
sar -n DEV 1 -o /root/sar1.out &> /dev/null
sar -n DEV -f /root/sar1.out |less
sar -n DEV -f /root/sar.out |egrep "ens4f0|ens5f0" > 1
awk '$6>200000.00{print;}' 1 > 2
awk '$7>200000.00{print;}' 1 > 3
</pre>