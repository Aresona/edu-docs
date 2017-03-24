nova_database:
  mysql_database.present:
    - names:
      - {{ pillar['nova']['NOVA_DATABASE'] }}
      - {{ pillar['nova']['NOVA_API_DATABASE'] }}
nova_local:
  mysql_user.present:
    - name: {{ pillar['nova']['NOVA_USERNAME'] }}
    - host: {{ pillar['nova']['HOST_LOCAL'] }}
    - password: {{ pillar['nova']['NOVA_PASSWORD'] }}
nova_other:
  mysql_user.present:
    - name: {{ pillar['nova']['NOVA_USERNAME'] }}
    - host: "{{ pillar['nova']['HOST_OTHER'] }}"
    - password: {{ pillar['nova']['NOVA_PASSWORD'] }}
nova_grant_local:
  mysql_grants.present:
    - grant: {{ pillar['nova']['PRIVILEGES'] }}
    - database: nova.*
    - user: {{ pillar['nova']['NOVA_USERNAME'] }}
    - host: {{ pillar['nova']['HOST_LOCAL'] }}
nova_grant_other:
  mysql_grants.present:
    - grant: {{ pillar['nova']['PRIVILEGES'] }}
    - database: nova.*
    - user: {{ pillar['nova']['NOVA_USERNAME'] }}
    - host: "{{ pillar['nova']['HOST_OTHER'] }}"

nova_api_grant_local:
  mysql_grants.present:
    - grant: {{ pillar['nova']['PRIVILEGES'] }}
    - database: nova_api.*
    - user: {{ pillar['nova']['NOVA_USERNAME'] }}
    - host: {{ pillar['nova']['HOST_LOCAL'] }}
nova__api_grant_other:
  mysql_grants.present:
    - grant: {{ pillar['nova']['PRIVILEGES'] }}
    - database: nova_api.*
    - user: {{ pillar['nova']['NOVA_USERNAME'] }}
    - host: "{{ pillar['nova']['HOST_OTHER'] }}"
/etc/nova_init.sh:
  file.managed:
    - source: salt://openstack-controller/pkg/files/nova_init.sh
    - user: root
    - group: root
    - mode: 700
    - template: jinja
nova-keystone:
  cmd.run:
    - name: /etc/nova_init.sh && rm -f /etc/nova_init.sh && touch {{ pillar['LOCK_PATH'] }}/nova_keystone.lock
    - unless: test -f {{ pillar['LOCK_PATH'] }}/nova_keystone.lock  

install-nova:
  pkg.installed:
    - names:
      - openstack-nova-api
      - openstack-nova-conductor
      - openstack-nova-console
      - openstack-nova-novncproxy
      - openstack-nova-scheduler
/etc/nova/nova.conf:
  file.managed:
    - source: salt://openstack-controller/pkg/files/nova.conf
    - user: root
    - group: nova
    - mode: 640
    - template: jinja
    - require:
      - pkg: install-nova
nova-populate:
  cmd.run:
    - name: su -s /bin/sh -c "nova-manage api_db sync" nova && su -s /bin/sh -c "nova-manage db sync" nova && touch  {{ pillar['LOCK_PATH'] }}/nova-populate.lock
    - unless: test -f {{ pillar['LOCK_PATH'] }}/nova-populate.lock
    - require:
      - file: /etc/nova/nova.conf
nova-service:
  service.running:
    - names:
      - openstack-nova-api
      - openstack-nova-consoleauth
      - openstack-nova-scheduler
      - openstack-nova-conductor
      - openstack-nova-novncproxy
    - enable: True
    - require:
      - cmd: nova-populate
    - watch:
      - file: /etc/nova/nova.conf
