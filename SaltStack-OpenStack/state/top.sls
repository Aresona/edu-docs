base:
  tai.novalocal:
    - openstack-common.init.init
    - openstack-common.pkg.pkg
    - openstack-slaves.slave
    - openstack-common.dashboard.dashboard
  controller:
    - openstack-common.init.init
    - openstack-common.pkg.pkg
    - openstack-controller.pkg.master
