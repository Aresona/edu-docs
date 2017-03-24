include:
  - openstack-controller.pkg.memcached
openstack-dashboard:
  pkg.installed:
    - name: openstack-dashboard
/etc/openstack-dashboard/local_settings:
  file.managed:
    - source: salt://openstack-common/dashboard/files/local_settings
    - user: root
    - group: apache
    - mode: 640
    - template: jinja
    - backup: minion
    - require:
      - pkg: openstack-dashboard
    - watch_in:
      - service: memcache-service 
dashboard-httpd:
  pkg.installed:
    - name: httpd
  service.running:
    - name: httpd
    - enable: True
    - watch:
      - file: /etc/openstack-dashboard/local_settings
    - require:
      - pkg: dashboard-httpd
