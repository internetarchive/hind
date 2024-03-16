#!/bin/sh
set -eu

# sets up HinD, passing on any extra CLI optional arguments for customizations

export HOST_UNAME=$(uname)
export FQDN=$(hostname -f)

podman -v > /dev/null || echo 'please install the podman package first'
podman -v > /dev/null || exit 1


# in background, wait for the `bootstrap.sh`, running in the first `podman run` below, to finish
(
  while $(! podman secret ls |grep -q ' BOOTSTRAPPED '); do sleep 1; done
  podman commit -q hind-init localhost/hind
  podman secret rm BOOTSTRAPPED > /dev/null
) &


(
  IMG=ghcr.io/internetarchive/hind:main

  # In rare case this is a symlink, ensure we mount the proper source.
  # NOTE: we map in /var/lib/containers here so `podman secret create` inside the `podman run`
  # container will effect us, the outside/VM.
  VLC=$(realpath /var/lib/containers 2>/dev/null  ||  echo /var/lib/containers)

  set -x
  # We need to shared these 2 directories "inside" the running `hind` container, and "outside" on
  # the VM itself.  We want to persist HTTPS cert files, and any `data/alloc` directories setup
  # on the "inside" (eg: `nomad run`) need to be available to nomad jobs running on the outside/VM.
  mkdir -p -m777 /pv/CERTS
  mkdir -p -m777 /opt/nomad/data/alloc

  podman pull -q $IMG
  podman run --net=host --privileged --cgroupns=host \
    -v ${VLC}:/var/lib/containers \
    -e FQDN  -e HOST_UNAME \
    --rm --name hind-init -q "$@" $IMG
)


if [ "$HOST_UNAME" = Darwin ]; then
  ARGS='-p 6000:4646 -p 8000:80 -p 4000:443 -v /sys/fs/cgroup:/sys/fs/cgroup:rw'
else
  ARGS='--net=host'
fi


wait


# Now run the new docker image in the background.
# NOTE: we switch `-v /var/lib/containers` to volume mounting the `podman.sock`, since we want HinD
# container to `podman run` nomad jobs on the outside/VM, not inside itself
(
  SOCK=$(podman info |grep -F podman.sock |rev |cut -f1 -d ' ' |rev)
  set -x
  podman run --privileged --cgroupns=host \
    $ARGS \
    -v $SOCK:$SOCK \
    -v /opt/nomad/data/alloc:/opt/nomad/data/alloc \
    -v /pv:/pv \
    --secret HIND_C,type=env --secret HIND_N,type=env \
    --restart=always --name hind -d -q "$@" localhost/hind >/dev/null
)


if ( echo "$@" |grep -q  'e FIRST=' ); then
  echo '

SUCCESS!

'
  exit 0
fi


echo '
Congratulations!

In a few seconds, you should be able to access your nomad cluster, eg:
  nomad status

by setting these environment variables
(inside or outside the running container or from a home machine --
anywhere you have downloaded a `nomad` binary):
  '

if [ $HOST_UNAME = Darwin ]; then
  echo "export NOMAD_ADDR=http://$FQDN:6000"
else
  echo "export NOMAD_ADDR=https://$FQDN"
fi

podman run -q --rm --secret NOMAD_TOKEN,type=env hind sh -c 'echo export NOMAD_TOKEN=$NOMAD_TOKEN'
