openstack-neutron-linuxbridge:
  pkg.installed:
    - names:
      - openstack-neutron-linuxbridge
      - ebtables
      - ipset
config-neutron-neutron.conf:
  file.managed:
    - name: /etc/neutron/neutron.conf
    - source: salt://openstack-slaves/files/neutron.conf
    - user: root
    - group: neutron
    - mode: 640
    - backup: minion
    - template: jinja
    - require:
      - pkg: openstack-neutron-linuxbridge
config-neutron-linuxbridge:
  file.managed:
    - name: /etc/neutron/plugins/ml2/linuxbridge_agent.ini
    - source: salt://openstack-slaves/files/linuxbridge_agent.ini
    - user: root
    - group: neutron
    - mode: 640
    - backup: minion
    - template: jinja
    - require:
      - pkg: openstack-neutron-linuxbridge
neutron-agent-service:
  service.running:
    - name: neutron-linuxbridge-agent
    - enable: True
    - watch:
      - file: config-neutron-neutron.conf
      - file: config-neutron-linuxbridge
