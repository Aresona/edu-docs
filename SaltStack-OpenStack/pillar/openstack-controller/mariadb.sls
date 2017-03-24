{% if grains['host'] == 'controller' %}
bind-address: 192.168.1.162
mysql.host: 192.168.1.162
mysql.port: 3306
mysql.user: root
mysql.pass: "123456"
mysql.charset: utf8
{% endif %}
