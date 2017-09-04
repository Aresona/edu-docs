<pre>
yum install openldap openldap-clients openldap-servers
chown -R ldap:ldap /var/lib/ldap
systemctl stop slapd.service
</pre>
在centos7下ldap不再使用slapd.conf作为配置文件，而是使用一个配置数据库（`/etc/openldap/slapd.d/`），如果升级的话，可以把以前的配置文件转换成配置数据库的格式
<pre>
slaptest -f /etc/openldap/slapd.conf -F /etc/openldap/slapd.d/
</pre>
由于配置文件的语法错误会导致服务启动不起来，所以强烈建议不直接编辑LDIF文件

全局配置文件
`/etc/openldap/slapd.d/cn=config.ldif`

命令|功能|可用值|例子
-- | --| --
olcAllows	|	指定激活哪些功能 | bind_v2,bind_anon_cred,bind_anon_dn,update_anon,proxy_authz_anon| olcAllows: bind_v2 update_anon
olcConnMaxPending|指定一个session的最大pending requests| int，默认为100| olcConnMaxPending: 100
oclIdleTimeout| 指定close一个空连接的超时时间|int|olcIdleTimeout: number
olcLogFile| 指定日志文件| file| olcLogFile: /var/log/slapd.log

前端配置文件

`/etc/openldap/slapd.d/cn=config/olcDatabase={-1}frontend.ldif`  定义全局数据库选项，比如ACL

监控后端配置文件

`/etc/openldap/slapd.d/cn=config/olcDatabase={1}monitor.ldif` 一般会由自动更新，cn=Monitor这个前缀不能改。


数据库指定配置

`/etc/openldap/slapd.d/cn=config/olcDatabase={2}hdb.ldif` 

默认,ldap服务端使用 `hdb`不当后端数据库。

<pre>
[root@compute1 slapd.d]# cat /etc/openldap/slapd.d/cn=config/olcDatabase={2}hdb.ldif
# AUTO-GENERATED FILE - DO NOT EDIT!! Use ldapmodify.
# CRC32 f92568ee
dn: olcDatabase={2}hdb
objectClass: olcDatabaseConfig
objectClass: olcHdbConfig
olcDatabase: {2}hdb
olcDbDirectory: /var/lib/ldap
olcSuffix: dc=my-domain,dc=com
olcRootDN: cn=Manager,dc=my-domain,dc=com
olcDbIndex: objectClass eq,pres
olcDbIndex: ou,cn,mail,surname,givenname eq,pres,sub
structuralObjectClass: olcHdbConfig
entryUUID: bbe13cc2-226e-1037-97b0-9f1c2133eb77
creatorsName: cn=config
createTimestamp: 20170831080418Z
entryCSN: 20170831080418.793352Z#000000#000#000000
modifiersName: cn=config
modifyTimestamp: 20170831080418Z
</pre>

olcReadOnly   允许你使用只读模式的数据库

olcRootDN	允许指定不被ACL限制的用户。默认选项是: `cn=Manager,dn=my-domain,dc=com`

olcRootPw    指定 `olcRootDN` 的密码

olcSuffix		指令允许您指定要为其提供信息的域。


 