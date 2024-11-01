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
' |sudo tee /etc/ferm/input/nomad.conf


INTRA=/etc/ferm/input/nomad-intra.conf
echo '
# @see https://github.com/internetarchive/hind/blob/main/bin/ports-unblock.sh

# ===== INTERNALLY OPEN ===================================================================

# For webapps with 2+ containers that need to talk to each other.
# We want to allow internal access to the IP addressed "high ports" -- but not the public:
proto tcp mod conntrack ctorigsrc $CLUSTER     mod conntrack ctorigdstport 20000:45000 ACCEPT;
proto tcp mod conntrack ctorigsrc 10.88.0.0/16 mod conntrack ctorigdstport 20000:45000 ACCEPT;
proto tcp                                      mod conntrack ctorigdstport 20000:45000 DROP;

saddr      $CLUSTER proto tcp dport 20000:45000 ACCEPT;
saddr 172.17.0.0/16 proto tcp dport 20000:45000 ACCEPT;
saddr  10.88.0.0/16 proto tcp dport 20000:45000 ACCEPT;
                  # proto tcp dport 20000:45000 REJECT; # xxx figure out why
' |sudo tee $INTRA


(
  echo '
# @see https://github.com/internetarchive/hind/blob/main/bin/ports-unblock.sh

chain (CNI-FORWARD FORWARD NETAVARK_FORWARD) @preserve;

chain CNI-ADMIN {'
  cat $INTRA
  echo '
}'
) |sudo tee /etc/ferm/ferm.d/containers.conf



set -x

# ensure `@include '/etc/ferm/ferm.d/containers.conf';` appears in /etc/ferm/ferm.conf

sudo service ferm reload

sleep 5

sudo podman network reload -a
