# 生成MD5验证信息

<pre>
cd /usr/share/nginx/html/ceph
find ./ -type f|xargs md5sum > ceph.md5 
</pre>

# 验证内容完整

<pre>
md5sum -c ceph.md5|grep FAILED
</pre>

