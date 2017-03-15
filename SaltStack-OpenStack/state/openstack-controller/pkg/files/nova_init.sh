#!/bin/bash

source /etc/admin-openrc
openstack user create --domain {{ pillar['PROJECT_DOMAIN'] }} --password={{ pillar['nova']['AUTH_PASSWORD'] }} {{ pillar['nova']['AUTH_USER'] }}
openstack role add --project service --user {{ pillar['nova']['AUTH_USER'] }} admin
openstack service create --name {{ pillar['nova']['SERVICE_NAME']}} --description "OpenStack Compute" compute
openstack endpoint create --region RegionOne compute public http://{{ pillar['controller'] }}:8774/v2.1/%\(tenant_id\)s
openstack endpoint create --region RegionOne compute internal http://{{ pillar['controller'] }}:8774/v2.1/%\(tenant_id\)s
openstack endpoint create --region RegionOne compute admin http://{{ pillar['controller'] }}:8774/v2.1/%\(tenant_id\)s
