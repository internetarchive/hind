#!/bin/sh -eu

# sets up HinD, passing on any extra CLI optional arguments for customizations

export HOST_UNAME=$(uname)
export FQDN=$(hostname -f)

podman -v > /dev/null || echo 'please install the podman package first'
podman -v > /dev/null || exit 1

(
  while $(! podman secret ls |grep -q ' NOMAD_TOKEN '); do sleep 1; done
  podman commit -q hind-init hind # xxx
) &


(
  set -x
  # xxx document & why the 2 mkdirs on the outside/VM:
  mkdir -p -m777 /pv/CERTS
  mkdir -p -m777 /opt/nomad/data/alloc
  podman run --net=host --privileged --cgroupns=host \
    -v /var/lib/containers:/var/lib/containers \
    -e FQDN  -e HOST_UNAME \
    --rm --name hind-init --pull=always -q "$@" ghcr.io/internetarchive/hind:main
)

if [ "$HOST_UNAME" = Darwin ]; then
  ARGS='-p 6000:4646 -p 8000:80 -p 4000:443 -v /sys/fs/cgroup:/sys/fs/cgroup:rw'
else
  ARGS='--net=host'
fi

if ( echo "$@" |grep -Fq NFSHOME= ); then
  ARGS2='-v /home:/home'
else
  ARGS2=''
fi

wait

# now run the new docker image in the background
(
  set -x
  podman run --privileged --cgroupns=host \
    $ARGS $ARGS2 \
    -v /var/lib/containers:/var/lib/containers \
    -v /opt/nomad/data/alloc:/opt/nomad/data/alloc \
    -v /pv:/pv \
    --secret HIND_C,type=env --secret HIND_N,type=env \
    --restart=always --name hind -d -q "$@" localhost/hind >/dev/null
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

  if [ $HOST_UNAME = Darwin ]; then
    echo "export NOMAD_ADDR=http://$FQDN:6000"
  else
    echo "export NOMAD_ADDR=https://$FQDN"
  fi

  podman run --rm --secret NOMAD_TOKEN,type=env hind sh -c 'echo export NOMAD_TOKEN=$NOMAD_TOKEN'
else
  echo '

  SUCCESS!

  '
fi
