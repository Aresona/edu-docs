mysql:
  mysql_database.present:
    - name: keystone
keystone_local:
  mysql_user.present:
    - name: keystone
    - host: localhost
    - password: keystone
keystone_other:
  mysql_user.present:
    - name: keystone
    - host: "%"
    - password: keystone
keystone_grant_local:
  mysql_grants.present:
    - grant: all privileges
    - database: keystone.*
    - user: keystone
    - host: localhost
keystone_grant_other:
  mysql_grants.present:
    - grant: all privileges
    - database: keystone.*
    - user: keystone
    - host: "%"
install-packages:
  pkg.installed:
    - names:
      - openstack-keystone
      - httpd
      - mod_wsgi
/etc/keystone/keystone.conf:
  file.managed:
    - source: salt://openstack-controller/pkg/files/keystone.conf
    - user: keystone
    - group: keystone
    - mode: 640
    - backup: minion
    - template: jinja
    - require:
      - pkg: install-packages
database-populate:
  cmd.run:
    - name: su -s /bin/sh -c "keystone-manage db_sync" keystone && keystone-manage fernet_setup --keystone-user {{ pillar['KEYSTONE_USER'] }} --keystone-group {{ pillar['KEYSTONE_GROUP'] }} && keystone-manage credential_setup --keystone-user {{ pillar['KEYSTONE_USER'] }} --keystone-group {{ pillar['KEYSTONE_GROUP'] }} && touch {{ pillar['LOCK_PATH'] }}/keystone-manage.lock
    - unless: test -f {{ pillar['LOCK_PATH'] }}/keystone-manage.lock 
    - require:
      - file: /etc/keystone/keystone.conf
bootstrap:
  cmd.run:
    - name: keystone-manage bootstrap --bootstrap-password {{ pillar['ADMIN_PASS'] }} --bootstrap-admin-url http://{{ pillar['controller'] }}:35357/v3/ --bootstrap-internal-url http://{{ pillar['controller'] }}:35357/v3/ --bootstrap-public-url http://{{ pillar['controller'] }}:5000/v3/ --bootstrap-region-id RegionOne && touch {{ pillar['LOCK_PATH'] }}/keystone-bootstrap.lock
    - unless: test -f {{ pillar['LOCK_PATH'] }}/keystone-bootstrap.lock
    - require:
      - cmd: database-populate
/etc/keystone_init.sh:
  file.managed:
    - source: salt://openstack-controller/pkg/files/keystone_init.sh
    - user: root
    - group: root
    - mode: 700
    - template: jinja
    - require:
      - cmd: bootstrap
init:
  cmd.run:
    - name: /etc/keystone_init.sh && touch {{ pillar['LOCK_PATH'] }}/keystone-init.lock
    - unless: test -f {{ pillar['LOCK_PATH'] }}/keystone-init.lock
    - require:
      - file: /etc/keystone_init.sh
