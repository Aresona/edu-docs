{% if grains['host'] == 'controller' %}
KEYSTONE_USER: keystone
KEYSTONE_DBPASS: keystone
KEYSTONE_GROUP: keystone
ADMIN_PASS: keystone
USERNAME: admin
ADMIN_PROJECT: admin
USER_DOMAIN: Default
PROJECT_DOMAIN: Default
DEMO_PROJECT: demo
DEMO_USERNAME: demo
demo_password: demo
{% endif %}
