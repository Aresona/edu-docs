/etc/yum.repos.d/epel.repo:
  file.managed:
    - source: salt://openstack-common/init/files/epel.repo
    - user: root
    - group: root
    - mode: 644
/etc/yum.repos.d/centos.repo:
  file.managed:
    - source: salt://openstack-common/init/files/centos.repo
    - user: root
    - group: root
    - mode: 644
/etc/yum.repos.d/openstack-newton.repo:
  file.managed:
    - source: salt://openstack-common/init/files/openstack-newton.repo
    - user: root
    - group: root
    - mode: 644
      
