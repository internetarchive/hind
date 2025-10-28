#!/bin/zsh -eu
setopt HIST_NO_STORE

if [ ! -e /booted ]; then
  # create a new docker image with the bootstrapped version of your cluster
  ./bin/spinner "Bootstrapping your hind cluster..." /app/bin/bootstrap.sh
  exit 0
fi

rm -f  /opt/consul/serf/local.keyring  /opt/nomad/data/server/serf.keyring
sed -i "s^VEhJUy1HRVRTLVJFUExBQ0VELUlULURPRVMtUklMTFk=^$HIND_C^" $CONSUL_HCL
sed -i "s^VEhJUy1HRVRTLVJFUExBQ0VELUlULURPRVMtUklMTFk=^$HIND_N^"  $NOMAD_HCL

if [ $CLIENT_ONLY_NODE ]; then
  echo 'server { enabled = false }' >> $NOMAD_HCL
  sed -i -E 's/server = true/server = false/' $CONSUL_HCL
fi

# set for `nomad run` of jobs with `podman` driver
podman system service -t 0 & # xxx prolly add into supervisord for autorestart
# test
# sudo curl -v -s --unix-socket /run/podman/podman.sock http://d/v1.0.0/libpod/info


# 'caddy' and 'consul' need to talk to backend 'reverse_proxy' [IP]:[PORT] URLs directly and not
# over any http proxy
unset  HTTPS_PROXY  HTTP_PROXY  https_proxy  http_proxy

exec /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf
