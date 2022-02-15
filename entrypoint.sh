#!/bin/zsh -e

FI=/etc/hind

if [ ! -e $FI ]; then
  echo "Bootstrapping your hind cluster..."
  /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
  sleep 15

  echo export NOMAD_TOKEN=$(nomad acl bootstrap |fgrep 'Secret ID' |cut -f2- -d= |tr -d ' ') > $FI
  source $FI
  echo "export NOMAD_ADDR=https://$(hostname -f)" >> $FI
  chmod 400 $FI

  # verify nomad & consul accessible & working
  consul members
  nomad server members
  nomad node status

  docker commit hind hind

  echo 'Now `docker run` your new `hind` image (that we just created) like this:

docker run --net=host --privileged -v /var/run/docker.sock:/var/run/docker.sock -v --restart=always --name hind -d hind

  '

  exit 0
fi


exec /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf
