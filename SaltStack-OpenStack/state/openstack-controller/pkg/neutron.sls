neutron_database:
  mysql_database.present:
    - name: {{ pillar['neutron']['NEUTRON_DATABASE'] }}
neutron_local:
  mysql_user.present:
    - name: {{ pillar['neutron']['NEUTRON_USERNAME'] }}
    - host: {{ pillar['neutron']['HOST_LOCAL'] }}
    - password: {{ pillar['neutron']['NEUTRON_PASSWORD'] }}
neutron_other:
  mysql_user.present:
    - name: {{ pillar['neutron']['NEUTRON_USERNAME'] }}
    - host: "{{ pillar['neutron']['HOST_OTHER'] }}"
    - password: {{ pillar['neutron']['NEUTRON_PASSWORD'] }}
neutron_grant_local:
  mysql_grants.present:
    - grant: {{ pillar['neutron']['PRIVILEGES'] }}
    - database: neutron.*
    - user: {{ pillar['neutron']['NEUTRON_USERNAME'] }}
    - host: {{ pillar['neutron']['HOST_LOCAL'] }}
neutron_grant_other:
  mysql_grants.present:
    - grant: {{ pillar['neutron']['PRIVILEGES'] }}
    - database: neutron.*
    - user: {{ pillar['neutron']['NEUTRON_USERNAME'] }}
    - host: "{{ pillar['neutron']['HOST_OTHER'] }}"
/etc/neutron_init.sh:
  file.managed:
    - source: salt://openstack-controller/pkg/files/neutron_init.sh
    - user: root
    - group: root
    - mode: 700
    - template: jinja
neutron-keystone:
  cmd.run:
    - name: /etc/neutron_init.sh && rm -f /etc/neutron_init.sh && touch {{ pillar['LOCK_PATH'] }}/neutron_keystone.lock
    - unless: test -f {{ pillar['LOCK_PATH'] }}/neutron_keystone.lock  

install-neutron:
  pkg.installed:
    - names:
      - openstack-neutron
      - openstack-neutron-ml2
      - openstack-neutron-linuxbridge
      - ebtables
/etc/neutron/neutron.conf:
  file.managed:
    - source: salt://openstack-controller/pkg/files/neutron.conf
    - user: root
    - group: neutron
    - mode: 640
    - template: jinja
    - require:
      - pkg: install-neutron
/etc/neutron/plugins/ml2/ml2_conf.ini:
  file.managed:
    - source: salt://openstack-controller/pkg/files/ml2_conf.ini
    - user: root
    - group: neutron
    - mode: 640
    - template: jinja
    - backup: minion
    - require:
      - pkg: install-neutron
/etc/neutron/plugins/ml2/linuxbridge_agent.ini:
  file.managed:
    - source: salt://openstack-controller/pkg/files/linuxbridge_agent.ini
    - user: root
    - group: neutron
    - mode: 640
    - template: jinja
    - backup: minion
    - require:
      - pkg: install-neutron
/etc/neutron/dhcp_agent.ini:
  file.managed:
    - source: salt://openstack-controller/pkg/files/dhcp_agent.ini
    - user: root
    - group: neutron
    - mode: 640
    - template: jinja
    - backup: minion
    - require:
      - pkg: install-neutron
/etc/neutron/metadata_agent.ini:
  file.managed:
    - source: salt://openstack-controller/pkg/files/metadata_agent.ini
    - user: root
    - group: neutron
    - mode: 640
    - template: jinja
    - bakcup: minion
    - require:
      - pkg: install-neutron
/etc/neutron/plugin.ini:
  file.symlink:
    - target: /etc/neutron/plugins/ml2/ml2_conf.ini
neutron-populate:
  cmd.run:
    - name: su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron && touch {{ pillar['LOCK_PATH'] }}/neutron-populate.lock
    - unless: test -f {{ pillar['LOCK_PATH'] }}/neutron-populate.lock
neutron-server:
  service.running:
    - name: neutron-server
    - enable: True
    - watch:
      - file: /etc/neutron/neutron.conf
      - file: /etc/neutron/plugins/ml2/ml2_conf.ini 
neutron-linuxbridge-agent:
  service.running:
    - name: neutron-linuxbridge-agent
    - enable: True
    - watch:
      - file: /etc/neutron/plugins/ml2/linuxbridge_agent.ini
neutron-dhcp-agent:
  service.running:
    - enable: True
    - watch:
      - file: /etc/neutron/dhcp_agent.ini
neutron-metadata-agent:
  service.running:
    - enable: True
    - watch:
      - file: /etc/neutron/metadata_agent.ini 
