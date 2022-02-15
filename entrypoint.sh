#!/bin/zsh -e

FI=/etc/hind

if [ ! -e $FI ]; then
  /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
  ./spinner "Bootstrapping your hind cluster..." sleep 15 # xxx loop

  echo export NOMAD_TOKEN=$(nomad acl bootstrap |fgrep 'Secret ID' |cut -f2- -d= |tr -d ' ') > $FI
  source $FI
  echo "export NOMAD_ADDR=https://$(hostname -f)" >> $FI
  chmod 400 $FI

  # verify nomad & consul accessible & working
  set -x
  consul members
  nomad server members
  nomad node status

  # create a new docker image with the bootstrapped version of your cluster
  docker commit hind hind

  # now run the new docker image in the background
  docker run --net=host --privileged -v /var/run/docker.sock:/var/run/docker.sock -v --restart=always --name hindup -d hind
  set +x

  echo '
Congratulations!

You should be able to access your nomad cluster by setting these environment variables
(inside or outside the container or from a home machine -- anywhere you have downloaded `nomad` binary):
  '
  cat $FI

  exit 0
fi


exec /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf
