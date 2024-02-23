#!/bin/zsh -eu

# sets up HinD, passing on any extra CLI optional arguments xxx

export FIRST= #xxx
export TOK_C= #xxx
export TOK_N= #xxx

export CONFIG=/etc/hind
export FQDN=$(hostname -f)
export HOST_UNAME=$(uname)

(
  set -x
  sudo mkdir -p -m777 /pv/CERTS # xxx
  sudo podman run --net=host --privileged --cgroupns=host \
    -v /var/lib/containers:/var/lib/containers \
    -e FQDN  -e HOST_UNAME  -e CONFIG  -e FIRST  -e TOK_C  -e TOK_N \
    -v /pv/CERTS:/pv/CERTS \
    --rm --name hind --pull=always "$@" ghcr.io/internetarchive/hind:podman
    # xxx :main
)

# now run the new docker image in the background
typeset -a ARGS
if [ "$HOST_UNAME" = Darwin ]; then
  ARGS+=(-p 6000:4646 -p 8000:80 -p 4000:443 -v /sys/fs/cgroup:/sys/fs/cgroup:rw)
else
  ARGS+=(--net=host)
fi

(
  set -x
  sudo podman run $ARGS --privileged --cgroupns=host \
    -v /var/lib/containers:/var/lib/containers \
    --restart=unless-stopped --name hindup -v /pv/CERTS:/root/.local/share/caddy -d hind >/dev/null
)

if [ ! $FIRST ]; then
  echo '
  Congratulations!

  In a few seconds, you should be able to access your nomad cluster, eg:
    nomad status

  by setting these environment variables
  (inside or outside the running container or from a home machine --
  anywhere you have downloaded a `nomad` binary):
    '
  sudo podman run --rm hind cat $CONFIG
else
  echo '

  SUCCESS!

  '
fi
