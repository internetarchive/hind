#!/bin/zsh -eu

export CONFIG=/etc/hind

export FIRST=${FIRST:-""}

if [ ! -e $CONFIG ]; then
  # create a new docker image with the bootstrapped version of your cluster
  ./bin/spinner "Bootstrapping your hind cluster..." /app/bin/bootstrap.sh
  ./bin/spinner 'cleanly shutting down' /app/bin/shutdown.sh
  ./bin/spinner 'committing bootstrapped image' podman commit hind hind

else
  exec /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf
fi
