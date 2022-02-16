#!/bin/zsh

# try up to ~10m to bootstrap nomad

for try in $(seq 0 600)
do
  nomad acl bootstrap >| /tmp/bootstrap
  [ "$?" = "0" ] && break
  sleep 1
done
