/etc/admin-openrc:
  file.managed:
    - source: salt://openstack-controller/pkg/files/admin-openrc
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - backup: minion
/etc/demo-openrc:
  file.managed:
    - source: salt://openstack-controller/pkg/files/demo-openrc
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - backup: minion
