rabbitmq-server:
  pkg.installed
rabbitmq-start:
  service.running:
    - name: rabbitmq-server
    - enable: True
    - reload: True
    - require:
      - pkg: rabbitmq-server
rabbimq-user:
  cmd.run:
    - name: rabbitmqctl add_user {{ pillar['RABBIT_USER'] }} {{ pillar['RABBIT_PASS'] }} && rabbitmqctl set_permissions {{ pillar['RABBIT_USER'] }} ".*" ".*" ".*" && rabbitmqctl set_user_tags {{ pillar['RABBIT_USER'] }} administrator && touch {{ pillar['LOCK_PATH'] }}/rabbit-user.lock
    - require:
      - service: rabbitmq-start
    - unless: test -f {{ pillar['LOCK_PATH'] }}/rabbit-user.lock
web-plugin:
  rabbitmq_plugin.enabled:
    - name: rabbitmq_management
