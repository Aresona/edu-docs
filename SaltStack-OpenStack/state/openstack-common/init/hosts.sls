/etc/hosts:
  file.managed:
    - source: salt://openstack-common/init/files/hosts
    - user: root
    - group: root
    - mode: 644
