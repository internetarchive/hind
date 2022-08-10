#!/bin/zsh -e

FI=/etc/hind

if [ ! -e $FI ]; then
  /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
  ./bin/spinner "Bootstrapping your hind cluster..." /app/bin/bootstrap.sh

  echo export NOMAD_TOKEN=$(fgrep 'Secret ID' /tmp/bootstrap |cut -f2- -d= |tr -d ' ') > $FI
  source $FI

 typeset -a ARGS
  if [ "$HOST_UNAME" = "Darwin" ]; then
    ARGS+=(-p 6000:4646 -p 8000:80 -p 4000:443 -v /sys/fs/cgroup:/sys/fs/cgroup:rw)
    echo "export NOMAD_ADDR=http://$HOST_HOSTNAME:6000" >> $FI
  else
    ARGS+=(--net=host)
    echo "export NOMAD_ADDR=https://$HOST_HOSTNAME" >> $FI
  fi


  chmod 400 $FI
  rm /tmp/bootstrap

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

  echo '
Congratulations!

In a few seconds, you should be able to access your nomad cluster, eg:
   nomad status

by setting these environment variables
(inside or outside the running container or from a home machine --
 anywhere you have downloaded a `nomad` binary):
  '
  cat $FI

  exit 0
fi


exec /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf
