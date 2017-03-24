#!/bin/bash

source /etc/admin-openrc
openstack user create --domain {{ pillar['PROJECT_DOMAIN'] }} --password={{ pillar['neutron']['AUTH_PASSWORD'] }} {{ pillar['neutron']['AUTH_USER'] }}
openstack role add --project service --user {{ pillar['neutron']['AUTH_USER'] }} admin
openstack service create --name {{ pillar['neutron']['SERVICE_NAME']}} --description "OpenStack Networking" network
openstack endpoint create --region RegionOne network public http://{{ pillar['controller'] }}:9696
openstack endpoint create --region RegionOne network internal http://{{ pillar['controller'] }}:9696
openstack endpoint create --region RegionOne network admin http://{{ pillar['controller'] }}:9696
