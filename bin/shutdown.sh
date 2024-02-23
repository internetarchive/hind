#!/bin/zsh -eu

# cleanly shutdown so we dont have a dangling supervisord socket at `podman commit` time

cd /etc/supervisor
supervisorctl stop nomad
supervisorctl stop consul
supervisorctl stop consul-template
supervisorctl stop caddy-restarter
supervisorctl shutdown
sleep 5
