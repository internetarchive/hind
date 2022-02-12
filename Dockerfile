FROM ubuntu:focal

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

RUN apt-get -yqq update  && \
    apt-get -yqq --no-install-recommends install  \
      zsh  sudo  rsync  dnsutils  supervisor  curl  wget \
      apt-transport-https  ca-certificates  software-properties-common  gpgv2  gpg-agent && \
    # install binaries and service files
    #   eg: /usr/bin/nomad  /etc/nomad.d/nomad.hcl  /usr/lib/systemd/system/nomad.service
    curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add -  && \
    apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" && \
    apt-get -yqq update  && \
    apt-get -yqq install  nomad  consul  consul-template  && \
    wget -qO /usr/bin/caddy 'https://caddyserver.com/api/download?os=linux&arch=amd64'  && \
    chmod +x /usr/bin/caddy


WORKDIR /app
COPY   install-docker-ce.sh .
RUN  ./install-docker-ce.sh

COPY . .

COPY hind/supervisord.conf /etc/supervisor/conf.d/
COPY hind/Caddyfile.ctmpl  /etc/

RUN cat hind/nomad.hcl  >> /etc/nomad.d/nomad.hcl  && \
    cat hind/consul.hcl >> /etc/consul.d/consul.hcl  && \
    # for persistent volumes
    mkdir -m777 /pv  && \
    # start up nomad, consul, etc.
    supervisord  &&  sleep 15  && \
    # setup nomad credentials
    echo "export NOMAD_ADDR=http://localhost:4646" > $HOME/.nomad  && \
    echo export NOMAD_TOKEN=$(nomad acl bootstrap |fgrep 'Secret ID' |cut -f2- -d= |tr -d ' ') >> $HOME/.nomad  && \
    chmod 400 $HOME/.nomad  && \
    . $HOME/.nomad  && \
    # verify nomad & consul accessible & working
    consul members  && \
    nomad server members  && \
    nomad node status

CMD [ "/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf" ]
