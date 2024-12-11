#! /bin/zsh -eux

# Creates a lessor-scoped `NOMAD_TOKEN` that has readonly (primarily) access to the nomad cluster

# With the resulting NOMAD_TOKEN, a person, from cmd-line or GUI can do things like:
#  Login with basic access to GUI at NOMAD_ADDR (can't use 'topology' graph though, for instance)
#    GUI `ssh` in, inspection, etc.
#  Run various command line commands like:
#    nomad status
#  Use our convenience https://gitlab.com/internetarchive/nomad/-/blob/master/aliases on the command line, eg:
#    nom-ssh
#    nom-status
#    nom-logs

NAMESPACE=${1:?"Usage: <namespace to use, eg: appteam or default>"}


# setup the policy
FI=${NAMESPACE}-ro.policy.hcl
echo '
namespace "'$NAMESPACE'" {
  policy = "read"
  capabilities = [
    "alloc-exec",
    "dispatch-job",
    "list-jobs",
    "read-job",
    "read-logs",
  ]
} ' |tee $FI

nomad acl policy apply -description "$NAMESPACE readonly access" $NAMESPACE-readonly $FI
rm -fv $FI

# mint a NOMAD_TOKEN
nomad acl token create -name=$NAMESPACE-readonly -policy=$NAMESPACE-readonly -type=client |grep -E ^Secret |cut -f2- -d=
