glance_database:
  mysql_database.present:
    - name: {{ pillar['glance']['DATABASE'] }}
glance_local:
  mysql_user.present:
    - name: {{ pillar['glance']['USERNAME'] }}
    - host: {{ pillar['glance']['HOST_LOCAL'] }}
    - password: {{ pillar['glance']['PASSWORD'] }}
glance_other:
  mysql_user.present:
    - name: {{ pillar['glance']['USERNAME'] }}
    - host: "{{ pillar['glance']['HOST_OTHER'] }}"
    - password: {{ pillar['glance']['PASSWORD'] }}
glance_grant_local:
  mysql_grants.present:
    - grant: {{ pillar['glance']['PRIVILEGES'] }}
    - database: glance.*
    - user: {{ pillar['glance']['USERNAME'] }}
    - host: {{ pillar['glance']['HOST_LOCAL'] }}
glance_grant_other:
  mysql_grants.present:
    - grant: {{ pillar['glance']['PRIVILEGES'] }}
    - database: glance.*
    - user: {{ pillar['glance']['USERNAME'] }}
    - host: "{{ pillar['glance']['HOST_OTHER'] }}"

/etc/glance_init.sh:
  file.managed:
    - source: salt://openstack-controller/pkg/files/glance_init.sh
    - user: root
    - group: root
    - mode: 700
    - template: jinja
glance-keystone:
  cmd.run:
    - name: /etc/glance_init.sh && rm -f /etc/glance_init.sh && touch {{ pillar['LOCK_PATH'] }}/glance_keystone.lock
    - unless: test -f {{ pillar['LOCK_PATH'] }}/glance_keystone.lock  

install-glance:
  pkg.installed:
    - name: openstack-glance
/etc/glance/glance-api.conf:
  file.managed:
    - source: salt://openstack-controller/pkg/files/glance-api.conf
    - user: root
    - group: glance
    - mode: 640
    - template: jinja
    - require:
      - pkg: install-glance

/etc/glance/glance-registry.conf:
  file.managed:
    - source: salt://openstack-controller/pkg/files/glance-registry.conf
    - user: root
    - group: glance
    - mode: 640
    - template: jinja
    - require:
      - pkg: install-glance

glance_populate:
  cmd.run:
    - name: su -s /bin/sh -c "glance-manage db_sync" glance && touch {{ pillar['LOCK_PATH'] }}/glance_populate.lock
    - unless: test -f {{ pillar['LOCK_PATH'] }}/glance_populate.lock
    - require:
      - file: /etc/glance/glance-api.conf
      - file: /etc/glance/glance-registry.conf
glance_service:
  service.running:
    - names:
      - openstack-glance-api
      - openstack-glance-registry
    - enable: True
    - reload: True
    - require:
      - cmd: glance_populate
