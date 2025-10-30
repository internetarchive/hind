#!/bin/sh
set -eu

# sets up HinD, passing on any extra CLI optional arguments for customizations

VERBOSE=${VERBOSE:-""}
OUT=/dev/null
QUIET='-q'
if [ $VERBOSE ]; then
  # you can switch on verbose mode like this, running as root:
  # export VERBOSE=1; curl -sS https://internetarchive.github.io/hind/install.sh | sh -s
  OUT=/dev/stdout
  QUIET=
  echo '[chatty mode]'
  set -x
fi

export HOST_UNAME=$(uname)
export FQDN=$(hostname -f)

podman -v > /dev/null || echo 'please install the podman package first'
podman -v > /dev/null || exit 1

# NOTE: we use `podman.sock`, since we want HinD containers to create secrets and
# `podman run` nomad jobs on the outside/VM, not inside itself
SOCK=$(podman info |grep -F podman.sock |rev |cut -f1 -d ' ' |rev)
ARGS_SOCK="-v ${SOCK}:/run/podman/podman.sock"
ARGS_RUN="$ARGS_SOCK -v /opt/nomad/data/alloc:/opt/nomad/data/alloc --secret HIND_C,type=env --secret HIND_N,type=env"

# debian:trixie seems to not setup the podman socket by default
( set +ex;  systemctl enable podman )
( set +ex;  systemctl is-enabled podman )

# increase the locks limit, if we can
if [ -e /usr/share/containers/containers.conf ]; then
  # debian:trixie
  sed -i -E 's|#*num_locks\s*=\s*[0-9]+|num_locks = 8192|' /usr/share/containers/containers.conf
  rm -fv /dev/shm/libpod_lock
  podman system renumber
fi

if [ $HOST_UNAME = Darwin ]; then
  # setup socket so podman remote will work
  # https://github.com/containers/podman/blob/main/docs/tutorials/mac_win_client.md
  podman machine ssh 'systemctl --user enable --now podman.socket'
  podman machine ssh 'sudo loginctl enable-linger $USER'
  podman machine ssh 'sudo mkdir -p -m777 /opt/nomad/data/alloc'

  PV=$HOME/pv
  export FQDN=http://$FQDN

  ARGS_SEC="--cap-add SYS_ADMIN --security-opt seccomp=unconfined"
  ARGS_INIT="$ARGS_SEC"
  ARGS_RUN="$ARGS_SEC $ARGS_RUN -p 8000:80 -p 4000:443 -p 5555:5000"
else
  PV=/pv
  # Use host characteristics
  ARGS_MISC="--net=host --cgroupns=host"
  # Avoid HTTP(S)_PROXY vars automatically "leaking" in to the built container image
  ARGS_INIT="$ARGS_MISC --http-proxy=false"
  # Avoid "cannot fork process" periodic issues after running for weeks (go over linux default 2048)
  ARGS_RUN="$ARGS_MISC $ARGS_RUN --pids-limit 8192"
fi


(
  # clear any prior run (likely fail?)
  set +e
  podman stop  hind
  podman stop  hind-init
  podman rm -v hind
  podman rm -v hind-init
  if ( echo "$@" |grep -qv  'e FIRST=' ); then
    podman secret rm HIND_N
    podman secret rm HIND_C
  fi
  podman secret rm NOMAD_TOKEN
  set -e
) > $OUT 2>&1


(
  # bootstrap the general image to a customized image for your cluster, leveraging podman secrets
  IMG=ghcr.io/internetarchive/hind:main

  set -x
  # We need to share these 2 directories "inside" the running `hind` container, and "outside" on
  # the VM itself.  We want to persist HTTPS cert files, and any `data/alloc` directories setup
  # on the "inside" (eg: `nomad run`) need to be available to nomad jobs running on the outside/VM.
  mkdir -p -m777 $PV/CERTS
  mkdir -p -m777 /opt/nomad/data/alloc

  podman pull $QUIET $IMG > $OUT
  podman run --privileged $ARGS_INIT $ARGS_SOCK -e FQDN -e HOST_UNAME --name hind-init $QUIET "$@" $IMG
  podman commit $QUIET hind-init localhost/hind > $OUT 2>&1
  podman rm  -v        hind-init > $OUT 2>&1
)



# Now run the new docker image in the background.
(
  set -x
  podman run --privileged $ARGS_RUN -v ${PV}:/pv --restart=always --name hind -d $QUIET "$@" localhost/hind \
    > $OUT 2>&1
)


if ( echo "$@" |grep -q  'e FIRST=' ); then
  echo '

SUCCESS!

'
  exit 0
fi

set +x

echo '
Congratulations!

In a few seconds, you should be able to access your nomad cluster, eg:
  nomad status

by setting these environment variables
(inside or outside the running container or from a home machine --
anywhere you have downloaded a `nomad` binary):
  '

if [ $HOST_UNAME = Darwin ]; then
  echo "export NOMAD_ADDR=$FQDN:8000"
else
  echo "export NOMAD_ADDR=https://$FQDN"
fi

podman run $QUIET --rm --secret NOMAD_TOKEN,type=env hind sh -c 'echo export NOMAD_TOKEN=$NOMAD_TOKEN'
