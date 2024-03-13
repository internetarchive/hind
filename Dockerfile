FROM ubuntu:rolling

ENV FQDN hostname-default

# defaults unless admin passes in overrides
ENV NOMAD_ADDR_EXTRA    ""
ENV UNKNOWN_SERVICE_404 "https://archive.org/about/404.html"
ENV NFSHOME             ""
ENV TRUSTED_PROXIES     "private_ranges"
ENV FIRST               ""
ENV REVERSE_PROXY       ""
ENV ON_DEMAND_TLS_ASK   ""
ENV HOST_UNAME Linux

ENV DEBIAN_FRONTEND noninteractive
ENV TZ Etc/UTC
ENV TERM xterm
ENV ARCH "dpkg --print-architecture"

ENV NOMAD_HCL  /etc/nomad.d/nomad.hcl
ENV CONSUL_HCL /etc/consul.d/consul.hcl
ENV KEY_HASHI  /usr/share/keyrings/hashicorp-archive-keyring.gpg

EXPOSE 80 443

RUN apt-get -yqq update  && \
    apt-get -yqq --no-install-recommends install  \
    zsh  sudo  rsync  dnsutils  supervisor  curl  wget  iproute2  \
    apt-transport-https  ca-certificates  software-properties-common  gpgv2  gpg-agent  \
    podman  aardvark-dns  unzip && \
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

COPY . .

RUN cp etc/supervisord.conf /etc/supervisor/conf.d/  && \
    # make it so `supervisorctl status` can work in any dir, esp. /app/:
    rm etc/supervisord.conf && \
    ln -s /app/etc/Caddyfile.ctmpl  /etc/  && \
    cat etc/nomad.hcl  >> ${NOMAD_HCL}  && \
    cat etc/consul.hcl >> ${CONSUL_HCL}  && \
    ( git config --unset http.https://github.com/.extraheader || echo hmm )

CMD /app/bin/entrypoint.sh
