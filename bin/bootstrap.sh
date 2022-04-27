#!/bin/zsh

# try up to ~10m to bootstrap nomad

touch /tmp/bootstrap
for try in $(seq 0 600)
do
  nomad acl bootstrap 2>/tmp/boot.log >> /tmp/bootstrap
  [ "$?" = "0" ] && break
  ( fgrep 'ACL bootstrap already done' /tmp/boot.log ) && break
  sleep 1
done
