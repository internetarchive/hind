# FROM ubuntu:rolling # xxx no hashi pkgs for ubuntu "lunar" yet..
FROM ubuntu:kinetic

ENV FQDN hostname-default

# defaults unless admin passes in overrides
ENV NOMAD_ADDR_EXTRA    ""
ENV UNKNOWN_SERVICE_404 "https://archive.org/about/404.html"
# xxx hookup NFS_PV
ENV NFSHOME             ""
ENV NFS_PV              ""
ENV TRUSTED_PROXIES     "private_ranges"
ENV FIRST               ""

ENV DEBIAN_FRONTEND noninteractive
ENV TZ Etc/UTC
ENV TERM xterm
ENV ARCH "dpkg --print-architecture"
ENV HOST_UNAME Linux

ENV NOMAD_HCL  /etc/nomad.d/nomad.hcl
ENV CONSUL_HCL /etc/consul.d/consul.hcl
ENV KEY_HASHI  /usr/share/keyrings/hashicorp-archive-keyring.gpg

EXPOSE 80 443

RUN apt-get -yqq update  && \
    apt-get -yqq --no-install-recommends install  \
    zsh  sudo  rsync  dnsutils  supervisor  curl  wget  iproute2  \
    apt-transport-https  ca-certificates  software-properties-common  gpgv2  gpg-agent && \
    #
    # install binaries and service files
    #   eg: /usr/bin/nomad  $NOMAD_HCL  /usr/lib/systemd/system/nomad.service
    wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o ${KEY_HASHI} && \
    echo "deb [signed-by=${KEY_HASHI}] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
      >| /etc/apt/sources.list.d/hashicorp.list && \
    apt-get -yqq update  && \
    apt-get -yqq install  nomad  consul  consul-template  && \
    #
    # install caddy
    #   https://caddyserver.com/docs/install#debian-ubuntu-raspbian
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' \
      | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg && \
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' \
      >| /etc/apt/sources.list.d/caddy-stable.list && \
    apt-get -yqq update && \
    apt-get -yqq install caddy && \
    mkdir -p    /var/lib/caddy && \
    chown caddy /var/lib/caddy

WORKDIR /app
COPY   bin/install-docker-ce.sh bin/
RUN  ./bin/install-docker-ce.sh

COPY . .

RUN cp etc/supervisord.conf /etc/supervisor/conf.d/  && \
    ln -s /app/etc/Caddyfile.ctmpl  /etc/  && \
    cat etc/nomad.hcl  >> ${NOMAD_HCL}  && \
    cat etc/consul.hcl >> ${CONSUL_HCL}  && \
    # for persistent volumes
    mkdir -m777 /pv

CMD /app/bin/entrypoint.sh
