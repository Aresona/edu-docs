#!/bin/bash
export OS_USERNAME={{ pillar['USERNAME'] }}
export OS_PASSWORD={{ pillar['ADMIN_PASS'] }}
export OS_PROJECT_NAME={{ pillar['ADMIN_PROJECT'] }}
export OS_USER_DOMAIN_NAME={{ pillar['USER_DOMAIN'] }}
export OS_PROJECT_DOMAIN_NAME={{ pillar['PROJECT_DOMAIN'] }}
export OS_AUTH_URL=http://{{ pillar['controller'] }}:35357/v3
export OS_IDENTITY_API_VERSION=3

openstack project create --domain default --description "Service Project" service
openstack project create --domain default --description "Demo Project" demo
openstack user create --domain default --password={{ pillar['demo_password'] }} demo
openstack role create user
openstack role add --project demo --user demo user
