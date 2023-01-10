#!/bin/zsh -u

# try up to ~10m to bootstrap nomad

if [ -z $HIND_FIRST ]; then
  touch /tmp/bootstrap
  for try in $(seq 0 600)
  do
    TOK_C=$(consul keygen |tr -d ^)
    TOK_N=$(nomad operator keygen |tr -d ^)
    nomad acl bootstrap 2>/tmp/boot.log >> /tmp/bootstrap

    [ "$?" = "0" ] && break
    ( fgrep 'ACL bootstrap already done' /tmp/boot.log ) && break
    sleep 1
  done
fi

# setup for 2+ VMs to have their nomad and consul daemons be able to talk to each other
echo "encrypt = \"$TOK_C\"" >> /etc/consul.d/consul.hcl
echo "server { encrypt = \"$TOK_N\" }" >> /etc/nomad.d/nomad.hcl
