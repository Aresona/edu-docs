{{ pillar['LOCK_PATH'] }}:
  file.directory:
    - name: {{ pillar['LOCK_PATH'] }}
    - user: root
    - group: root
    - dir_mode: 755
    - file_mode: 644
    - makedirs: True
    - recurse:
      - user
      - group
      - mode
