#!/bin/bash -exu

# This gets us DNS resolving on archive.org VMs, at the VM level (but _not_ inside containers)-8
# for hostnames like:
#   www-hello-world.service.consul
if [ -e /etc/dnsmasq.d/ ]; then
  echo "server=/consul/127.0.0.1#8600" |sudo tee /etc/dnsmasq.d/nomad
  # restart and give a few seconds to ensure server responds
  sudo systemctl restart dnsmasq
  sleep 2
fi
