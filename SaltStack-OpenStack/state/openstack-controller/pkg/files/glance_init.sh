#!/bin/bash

source /etc/admin-openrc
openstack user create --domain {{ pillar['PROJECT_DOMAIN'] }} --password={{ pillar['glance']['AUTH_PASSWORD'] }} {{ pillar['glance']['AUTH_USER'] }}
openstack role add --project service --user {{ pillar['glance']['AUTH_USER'] }} admin
openstack service create --name {{ pillar['glance']['SERVICE_NAME']}} --description "OpenStack Image" image
openstack endpoint create --region RegionOne image public http://{{ pillar['controller'] }}:9292
openstack endpoint create --region RegionOne image internal http://{{ pillar['controller'] }}:9292
openstack endpoint create --region RegionOne image admin http://{{ pillar['controller'] }}:9292
