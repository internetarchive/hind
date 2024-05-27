#!/bin/zsh -eu

export FIRST=${FIRST:-""}

echo      "name = \"$(hostname -s)\"" >> $NOMAD_HCL
echo "node_name = \"$(hostname -s)\"" >> $CONSUL_HCL

date > /booted

if [ $FIRST ]; then

  # setup for 2+ VMs to have their nomad and consul daemons be able to talk to each other
  export FIRSTIP=$(host $FIRST | perl -ane 'print $F[3] if $F[2] eq "address"' | head -1)

  echo "retry_join = [\"$FIRSTIP\"]" >> $CONSUL_HCL

  echo "server_join { retry_join = [ \"$FIRSTIP\" ] }" >> $NOMAD_HCL
  echo "server { bootstrap_expect = 2 }"               >> $NOMAD_HCL

else

  # single VM cluster and/or first VM in cluster
  echo 'bootstrap_expect = 1' >> $CONSUL_HCL

  # start agent so we can bootstrap nomad
  nomad agent -config /etc/nomad.d > /tmp/nom.log 2>&1 &

  touch /tmp/bootstrap
  # try up to ~10m to bootstrap nomad
  for try in $(seq 0 600)
  do
    set +e
    nomad acl bootstrap 2>/tmp/boot.log >> /tmp/bootstrap
    [ "$?" = "0" ] && break
    set -e

    ( grep -F 'ACL bootstrap already done' /tmp/boot.log ) && break
    sleep 1
  done
  set -e

  # clean shutdown agent
  pkill -SIGQUIT nomad
  sleep 5


  if [ "$HOST_UNAME" = Darwin ]; then
    apt-get install -yqq fuse-overlayfs
    echo; echo
    echo -n 'echo -n '
    grep -F 'Secret ID' /tmp/bootstrap |cut -f2- -d= |tr -d ' \n'
    echo  ' | podman secret create NOMAD_TOKEN -'
    echo; echo
  else
    consul keygen                                  |tr -d '^\n' | podman -r secret create HIND_C -
    nomad operator gossip keyring generate         |tr -d '^\n' | podman -r secret create HIND_N -
    grep -F 'Secret ID' /tmp/bootstrap |cut -f2- -d= |tr -d ' ' | podman -r secret create NOMAD_TOKEN -
  fi

  rm -f /tmp/*

fi
