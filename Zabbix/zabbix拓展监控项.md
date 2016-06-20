## zabbix-extensions

	git clone git@github.com:lesovsky/zabbix-extensions.git
	cd zabbix-extensions-master/files/postgresql/
	cp postgresql.conf /etc/zabbix/zabbix_agentd.d/
	导入模板
这个项目里面包含的其他模板

	[root@linux-node1 files]# ll|awk '{print $9}'
	
	cgroups
	flashcache
	glusterfs-client
	hwraid-adaptec
	hwraid-megacli
	hwraid-smartarray
	iostat
	keepalived
	linux
	memcached
	pgbouncer
	postfix
	postgresql
	redis
	skytools
	sphinx2
	testcookie
	unicorn
	yum-security
	zabbix-server