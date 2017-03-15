install-memcached:
  pkg.installed:
    - names:
      - memcached
      - python-memcached
memcache-configure:
  file.managed:
    - name: /etc/sysconfig/memcached
    - source: salt://openstack-controller/pkg/files/memcached
    - user: root
    - group: root
    - mode: 644
    - backup: minion
    - require:
      - pkg: install-memcached
memcache-service:
  service.running:
    - name: memcached
    - enable: True
    - watch:
      - file: memcache-configure
