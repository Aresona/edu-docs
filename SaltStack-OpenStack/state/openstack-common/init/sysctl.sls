net.ipv4.ip_local_port_range:
  sysctl.present:
    - value: 10000 65000
net.ipv4.tcp_fin_timeout:
  sysctl.present:
    - value: 2
net.ipv4.tcp_tw_reuse:
  sysctl.present:
    - value: 1
net.ipv4.tcp_tw_recycle:
  sysctl.present:
    - value: 1
net.ipv4.tcp_syncookies:
  sysctl.present:
    - value: 1
net.ipv4.tcp_keepalive_time:
  sysctl.present:
    - value: 600
net.ipv4.tcp_max_syn_backlog:
  sysctl.present:
    - value: 16384
net.ipv4.tcp_max_tw_buckets:
  sysctl.present:
    - value: 36000
net.ipv4.route.gc_timeout:
  sysctl.present:
    - value: 100
net.ipv4.tcp_syn_retries:
  sysctl.present:
    - value: 1
net.ipv4.tcp_synack_retries:
  sysctl.present:
    - value: 1
net.core.somaxconn:
  sysctl.present:
    - value: 16384
net.core.netdev_max_backlog:
  sysctl.present:
    - value: 16384
net.ipv4.tcp_max_orphans:
  sysctl.present:
    - value: 16384
fs.file-max:
  sysctl.present:
    - value: 2000000
vm.swappiness:
  sysctl.present:
    - value: 0
