selinux:
  cmd.run:
    - names:
      - setenforce 0
      - sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
