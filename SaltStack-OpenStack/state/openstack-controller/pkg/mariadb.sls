mariadb-install:
  pkg.installed:
    - names:
      - mariadb
      - mariadb-server
      - python2-PyMySQL
/etc/my.cnf.d/openstack.cnf:
  file.managed:
    - source: salt://openstack-controller/pkg/files/openstack.cnf
    - user: root
    - group: root
    - mode: 644
    - backup: minion
    - template: jinja
    - require:
      - pkg: mariadb-install
  service.running:
    - name: mariadb.service
    - enable: True
    - watch:
      - file: /etc/my.cnf.d/openstack.cnf
    - require:
      - pkg: mariadb-install
