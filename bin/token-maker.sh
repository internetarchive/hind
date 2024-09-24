#!/bin/zsh -eux

# Creates a lessor-scoped `NOMAD_TOKEN` that can be used with
# CI/CD custom var: `NOMAD_VAR_NAMESPACE`
# https://gitlab.com/internetarchive/nomad#custom-namespacing
# that can give full access to only deploys in the `NOMAD_VAR_NAMESPACE`

NAMESPACE=${1:?"Usage: <namespace to use, eg: ait>"}

# create new policy
echo 'namespace "'$NAMESPACE'" { policy="write" }' \
  | nomad acl policy apply $NAMESPACE -


# create namespace
DRIVER=podman
if [ "$NOMAD_ADDR" = "https://prod.archive.org" ]; then
  DRIVER=docker
fi
echo '
name = "'$NAMESPACE'"
description = "'$NAMESPACE' only access"
capabilities {
  enabled_task_drivers   = ["docker", "podman", "raw_exec"]
  disabled_task_drivers  = []
}
meta {
}
' |tee x.hcl
nomad namespace apply x.hcl
rm x.hcl


# create token
mkdir -p ~/.config/
TOK=$(nomad acl token create -name=$NAMESPACE -policy=$NAMESPACE -type=client \
  | grep -F 'Secret ID' |cut -f2- -d= |tr -d ' ')
(
  echo "export NOMAD_ADDR=$NOMAD_ADDR"
  echo "export NOMAD_TOKEN=$TOK"
  echo "export NOMAD_NAMESPACE=$NAMESPACE"
) |   tee ~/.config/nom-$NAMESPACE
chmod 400 ~/.config/nom-$NAMESPACE


# show the new setup
nomad acl policy list
nomad acl policy info $NAMESPACE

nomad namespace list
nomad namespace inspect $NAMESPACE

nomad acl token list
