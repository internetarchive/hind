/*
Readonly (primarily) access to the nomad cluster


With the resulting NOMAD_TOKEN, a person, from cmd-line or GUI can do things like:
  Login with basic access to GUI at NOMAD_ADDR (can't use 'topology' graph though, for instance)
    GUI `ssh` in, inspection, etc.
  Run various command line commands like:
    nomad status
    Use our convenience @see ../aliases on the command line, eg:
      nom-ssh
      nom-status
      nom-logs


Setup on your nomad cluster like below and retrieve a NOMAD_TOKEN from the `nom-readonly` file:

  nomad acl policy apply -description "readonly access" readonly read-access.hcl
  nomad acl token create -name="readonly token" -policy=readonly -type=client > ~/.config/nom-readonly
  chmod 400 ~/.config/nom-readonly

*/

namespace "default" {
  policy = "read"
  capabilities = [
    "alloc-exec",
    "dispatch-job",
    "list-jobs",
    "read-job",
    "read-logs",
  ]
}
