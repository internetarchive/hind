#!/bin/zsh -eu

export FIRST=${FIRST:-""}

if [ ! -e $CONFIG ]; then
  # create a new docker image with the bootstrapped version of your cluster
  ./bin/spinner "Bootstrapping your hind cluster..." /app/bin/bootstrap.sh
  ./bin/spinner 'cleanly shutting down' /app/bin/shutdown.sh
  ./bin/spinner 'committing bootstrapped image' podman commit -q hind-init hind
  exit 0
fi

setopt HIST_NO_STORE
sed -i "s/RUNTIME_REPLACED/$HIND_C/" $CONSUL_HCL
sed -i "s/RUNTIME_REPLACED/$HIND_N/" $NOMAD_HCL

# set for `nomad run` of jobs with `podman` driver
podman system service -t 0 & # xxx
# test
# sudo curl -v -s --unix-socket /run/podman/podman.sock http://d/v1.0.0/libpod/info

exec /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf
