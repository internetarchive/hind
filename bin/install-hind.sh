#!/bin/bash -eux

# sets up HinD like on the README.md, passing on any extra CLI optional arguments

sudo docker run --net=host --privileged -v /var/lib/containers:/var/lib/containers \
  -e FQDN=$(hostname -f) -e HOST_UNAME=$(uname) \
  --rm --name hind --pull=always \
  "$@" \
  ghcr.io/internetarchive/hind:main
