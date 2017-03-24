/etc/security/limits.conf:
  cmd.run:
    - name: echo '*      -       nofile      65535' >> /etc/security/limits.conf
    - unless: grep '*      -       nofile      65535' /etc/security/limits.conf
