#!/bin/zsh -eu
setopt HIST_NO_STORE

if [ ! -e /booted ]; then
  # create a new docker image with the bootstrapped version of your cluster
  ./bin/spinner "Bootstrapping your hind cluster..." /app/bin/bootstrap.sh

  # After having some problems w/ `podman commit` _on the inside_, we now do `podman commit` on the
  # outside (@see install.sh).  Wait for the podman image to show up to know we are done setup.
  ./bin/spinner 'committing bootstrapped image' zsh -c 'while $(! sudo podman images |grep -qE "^localhost/hind "); do sleep 3; done'

  exit 0
fi

sed -i "s^VEhJUy1HRVRTLVJFUExBQ0VELUlULURPRVMtUklMTFk=^$HIND_C^" $CONSUL_HCL
sed -i "s^VEhJUy1HRVRTLVJFUExBQ0VELUlULURPRVMtUklMTFk=^$HIND_N^"  $NOMAD_HCL

# set for `nomad run` of jobs with `podman` driver
podman system service -t 0 & # xxx prolly add into supervisord for autorestart
# test
# sudo curl -v -s --unix-socket /run/podman/podman.sock http://d/v1.0.0/libpod/info

exec /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf
