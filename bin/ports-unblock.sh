#!/bin/zsh -eu

# If you use ferm for firewalls, here's how we do at archive.org
# The lines with `$CLUSTER` here only allows access from other servers inside Internet Archive.
set -x
sudo mkdir -p /etc/ferm/input
set +x
echo '
# @see https://github.com/internetarchive/hind/blob/main/bin/ports-unblock.sh

# ===== WORLD OPEN =======================================================================

# loadbalancer main ports - open to world for http/s std. ports
proto tcp dport 443 ACCEPT;
proto tcp dport  80 ACCEPT;

# how you can expose a raw TCP port all way out to browser
proto tcp dport 7777 ACCEPT;


# ===== CLUSTER OPEN ======================================================================

# for nomad join
saddr $CLUSTER proto tcp dport 4647 ACCEPT;
saddr $CLUSTER proto tcp dport 4648 ACCEPT;

# for consul service discovery, DNS, join & more - https://www.consul.io/docs/install/ports
saddr $CLUSTER proto tcp dport 8600 ACCEPT;
saddr $CLUSTER proto udp dport 8600 ACCEPT;
saddr $CLUSTER proto tcp dport 8300 ACCEPT;
saddr $CLUSTER proto tcp dport 8301 ACCEPT;
saddr $CLUSTER proto udp dport 8301 ACCEPT;
saddr $CLUSTER proto tcp dport 8302 ACCEPT;
saddr $CLUSTER proto udp dport 8302 ACCEPT;

# try to avoid "ACL Token not found" - https://github.com/hashicorp/consul/issues/5421
saddr $CLUSTER proto tcp dport 8201 ACCEPT;
saddr $CLUSTER proto udp dport 8400 ACCEPT;
saddr $CLUSTER proto tcp dport 8500 ACCEPT;

# for consul join
saddr $CLUSTER proto tcp dport 8301 ACCEPT;

# locator UDP port for archive website
saddr $CLUSTER proto udp sport 8010 ACCEPT;
' |sudo tee /etc/ferm/input/nomad.conf

set -x


# xxx work w/ A to make `ferm.conf` changes stick

# change/ensure Chain FORWARD default policy to be DROP
sudo iptables -P FORWARD DROP


CNI=$(echo '
# ===== INTERNALLY OPEN ===================================================================
# For webapps with 2+ containers that need to talk to each other.
# The requesting/client IP addresses will be in the internal docker range of IP addresses.
#   Alternatively:   ( https://serverfault.com/a/1095754 )
#   iptables -I CNI-ADMIN -i eth0 -m conntrack --ctdir ORIGINAL -j DROP

chain CNI-ADMIN {
  saddr 207.241.224.0/20 proto tcp dport 20000:45000 ACCEPT;
  saddr    172.17.0.0/16 proto tcp dport 20000:45000 ACCEPT;
                         proto tcp dport 20000:45000 REJECT;
}' |grep -E -v '^#' |tr -d '\n' |tr -s ' ')


CONF=/etc/ferm/ferm.conf
sudo sed -i 's/chain .DOCKER.*/CNI-ADMIN {} chain (CNI-FORWARD FORWARD) @preserve;/' $CONF
sudo sed -i 's=CNI-ADMIN {}='$CNI'=' $CONF

sudo service ferm reload

sleep 5

sudo podman exec -it hind sh -c 'podman network reload -a'
