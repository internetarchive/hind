#!/bin/zsh -eu

FI=/etc/hind

HIND_FIRST=${HIND_FIRST:-""}

if [ ! -e $FI ]; then
  echo "name = $(hostname -s)" >> $NOMAD_HCL
  echo "node_name = $(hostname -s)" >> $CONSUL_HCL

  /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
  ./bin/spinner "Bootstrapping your hind cluster..." /app/bin/bootstrap.sh


  if [ ! $HIND_FIRST ]; then
    echo export NOMAD_TOKEN=$(fgrep 'Secret ID' /tmp/bootstrap |cut -f2- -d= |tr -d ' ') > $FI
    source $FI
  else
    echo 'dont delete this file' > $FI
  fi


  typeset -a ARGS
  if [ $HOST_UNAME = Darwin ]; then
    ARGS+=(-p 6000:4646 -p 8000:80 -p 4000:443 -v /sys/fs/cgroup:/sys/fs/cgroup:rw)
    echo "export NOMAD_ADDR=http://$HOST_HOSTNAME:6000" >> $FI
  else
    ARGS+=(--net=host)
    if [ ! $HIND_FIRST ]; then
      echo "export NOMAD_ADDR=https://$(hostname -f)" >> $FI
    fi
  fi

echo 'xxx  tls {
  http = true
  cert_file = "/opt/nomad/tls/tls.crt"
  key_file  = "/opt/nomad/tls/tls.key"
}'


  chmod 400 $FI
  rm -f /tmp/bootstrap

  # verify nomad & consul accessible & working
  echo
  echo
  consul members
  echo
  nomad server members
  echo

  # create a new docker image with the bootstrapped version of your cluster
  ./bin/spinner 'committing bootstrapped image' docker commit hind hind

  # now run the new docker image in the background
  docker run $ARGS --privileged -v /var/run/docker.sock:/var/run/docker.sock --restart=always --name hindup -d hind > /dev/null

  if [ ! $HIND_FIRST ]; then
    echo '
Congratulations!

In a few seconds, you should be able to access your nomad cluster, eg:
   nomad status

by setting these environment variables
(inside or outside the running container or from a home machine --
 anywhere you have downloaded a `nomad` binary):
    '
    cat $FI
  else
    echo '

SUCCESS!

    '
  fi

  exit 0
fi


exec /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf
