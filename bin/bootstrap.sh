#!/bin/zsh -u

HIND_FIRST=${HIND_FIRST:-""}

if [ ! $HIND_FIRST ]; then

  touch /tmp/bootstrap
  # try up to ~10m to bootstrap nomad
  for try in $(seq 0 600)
  do
    TOK_C=$(consul keygen | tr -d ^)
    TOK_N=$(nomad operator gossip keyring generate | tr -d ^)
    nomad acl bootstrap 2>/tmp/boot.log >> /tmp/bootstrap

    [ "$?" = "0" ] && break
    ( fgrep 'ACL bootstrap already done' /tmp/boot.log ) && break
    sleep 1
  done

  # setup for 2+ VMs to have their nomad and consul daemons be able to talk to each other
  echo "encrypt = \"$TOK_C\"" >> $CONSUL_HCL
  echo "server { encrypt = \"$TOK_N\" }" >> $NOMAD_HCL

else

  # try up to ~5m for consul to be up and happy
  for try in $(seq 0 300)
  do
    sleep 2
    consul members
    [ "$?" = "0" ] && break
  done

fi
