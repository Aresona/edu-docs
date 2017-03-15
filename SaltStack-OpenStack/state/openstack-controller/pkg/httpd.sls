include:
  - openstack-controller.pkg.keystone

/etc/httpd/conf/httpd.conf:
  file.managed:
    - source: salt://openstack-controller/pkg/files/httpd.conf
    - user: root
    - group: root
    - mode: 644
    - backup: minion
    - template: jinja
    - require:
      - pkg: install-packages
/etc/httpd/conf.d/wsgi-keystone.conf:
  file.symlink:
    - target: /usr/share/keystone/wsgi-keystone.conf
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: install-packages
httpd:
  service.running:
    - enable: True
    - watch:
      - file: /etc/httpd/conf/httpd.conf
