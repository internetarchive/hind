#!/bin/zsh -u

# cleanly & quietly shutdown so we dont have a dangling supervisord socket at `podman commit` time
(
  supervisorctl stop nomad
  supervisorctl stop consul
  supervisorctl stop consul-template
  supervisorctl stop caddy-restarter
  supervisorctl shutdown
  sleep 5

  # we want to persist https certs
  mkdir -p         /root/.local/share
  rm -rf           /root/.local/share/caddy
  ln -s /pv/CERTS  /root/.local/share/caddy
) >/dev/null 2>&1
