#!/bin/zsh -eu

# set for `nomad run` of jobs with `podman` driver
podman system service -t 0 & # xxx
# test
# sudo curl -v -s --unix-socket /run/podman/podman.sock http://d/v1.0.0/libpod/info

exec /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf
