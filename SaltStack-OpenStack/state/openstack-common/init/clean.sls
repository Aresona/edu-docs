clean:
  cmd.run:
      - name: /usr/bin/echo '00 00 * * * /bin/find /tmp -mtime +7 |xargs rm -rf &> /dev/null' >> /var/spool/cron/root
      - unless: grep '/bin/find /tmp -mtime +7 |xargs rm -rf &> /dev/null' /var/spool/cron/root
