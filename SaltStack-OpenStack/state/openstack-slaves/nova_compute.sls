openstack-nova-compute:
  pkg.installed:
    - names:
      - openstack-nova-compute
      - libvirt
nova.conf:
  file.managed:
    - name: /etc/nova/nova.conf
    - source: salt://openstack-slaves/files/nova.conf
    - user: root
    - group: nova
    - mode: 640
    - template: jinja
    - require:
      - pkg: openstack-nova-compute
/etc/vmx.sh:
  file.managed:
    - source: salt://openstack-slaves/files/vmx.sh
    - user: root
    - group: root
    - mode: 700
modify_nova:
  cmd.run:
    - name: sed -i '5675s/\#virt_type=kvm/virt_type=qemu/' /etc/nova/nova.conf 
    - require:
      - file: /etc/vmx.sh
      - file: nova.conf
    - unless: /bin/bash /etc/vmx.sh
compute_service:
  service.running:
    - names:
      - libvirtd
      - openstack-nova-compute
    - enable: True
    - watch:
      - file: nova.conf
    - require:
      - pkg: openstack-nova-compute
      - cmd: modify_nova
