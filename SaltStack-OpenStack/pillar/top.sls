base:
  controller:
    - openstack-controller.base
    - openstack-controller.lock
    - openstack-controller.mariadb
    - openstack-controller.rabbitmq
    - openstack-controller.keystone
    - openstack-controller.glance
    - openstack-controller.nova
    - openstack-controller.neutron
  tai.novalocal:
    - openstack-slaves.lock
    - openstack-slaves.nova
    - openstack-slaves.neutron
    - openstack-dashboard.dashboard
