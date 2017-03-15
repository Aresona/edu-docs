init-time:
  cmd.run:
    - names:
      - timedatectl set-timezone Asia/Shanghai
      - ntpdate ntp1.aliyun.com
write_update:
  cmd.run:
    - name:
      - echo '*/5 * * * * /usr/sbin/ntpdate ntp1.aliyun.com &> /dev/null' >> /var/spool/cron/root
    - unless: grep ntp1.aliyun.com /var/spool/cron/root
