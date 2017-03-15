/etc/bashrc:
  file.append:
    - text:
      - export PROMPT_COMMAND='{ msg=$(history 1| { read x y;echo $y; });logger "[euid=$(whoami)]":$(whoami):[`pwd`]"$msg"; }'
    - unless: grep 'export PROMPT_COMMAND' /etc/bashrc
