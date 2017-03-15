sshd:
  cmd.run:
    - names:
      - sed -i 's/#UseDNS yes/UseDNS no/' /etc/ssh/sshd_config 
      - sed -i 's/GSSAPIAuthentication yes/GSSAPIAuthentication no/' /etc/ssh/sshd_config
