#!/bin/zsh -eux

# Creates a lessor-scoped `NOMAD_TOKEN` that can be used in conjunction with
# CI/CD custom var: `NOMAD_VAR_NAMESPACE`
# https://gitlab.com/internetarchive/nomad#custom-namespacing


NAMESPACE=${1:?"Usage: <namespace to use, eg: appteam or default>"}


# setup the policy
FI=${NAMESPACE}-deploy.policy.hcl
echo '
namespace "'$NAMESPACE'" {
  name         = "'$NAMESPACE'-deploy"
  policy       = "read"
  capabilities = ["submit-job", "dispatch-job", "read-logs"]
} ' |tee $FI

# Apply the policy
nomad acl policy apply -description "$NAMESPACE deploy policy" $NAMESPACE-deploy $FI
rm -fv $FI

# Create the NOMAD_TOKEN
nomad acl token create -name=$NAMESPACE-deploy -type=client -global=false -policy=$NAMESPACE-deploy
