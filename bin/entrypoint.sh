#!/bin/zsh -eu

export CONFIG=/etc/hind

export FIRST=${FIRST:-""}

if [ ! -e $CONFIG ]; then
  # create a new docker image with the bootstrapped version of your cluster
  ./bin/spinner "Bootstrapping your hind cluster..." /app/bin/bootstrap.sh

  ./bin/spinner 'committing bootstrapped image' docker commit hind hind


  # now run the new docker image in the background
  typeset -a ARGS
  if [ $HOST_UNAME = Darwin ]; then
    ARGS+=(-p 6000:4646 -p 8000:80 -p 4000:443 -v /sys/fs/cgroup:/sys/fs/cgroup:rw)
  else
    ARGS+=(--net=host)
  fi
  docker run $ARGS --privileged -v /var/run/docker.sock:/var/run/docker.sock --restart=always --name hindup -v /pv/CERTS:/var/lib/caddy/.local/share/caddy/certificates/acme-v02.api.letsencrypt.org-directory -d hind > /dev/null


  if [ ! $FIRST ]; then
    echo '
Congratulations!

In a few seconds, you should be able to access your nomad cluster, eg:
   nomad status

by setting these environment variables
(inside or outside the running container or from a home machine --
 anywhere you have downloaded a `nomad` binary):
    '
    cat $CONFIG
  else
    echo '

SUCCESS!

    '
  fi

  exit 0
fi


exec /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf
