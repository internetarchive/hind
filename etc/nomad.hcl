addresses {
  http = "0.0.0.0"
}

advertise {
  http = "{{ GetInterfaceIP \"eth0\" }}"
  rpc = "{{ GetInterfaceIP \"eth0\" }}"
  serf = "{{ GetInterfaceIP \"eth0\" }}"
}

plugin "docker" {
  config {
    volumes {
      enabled = true
    }
  }
}

plugin "nomad-driver-podman" {
  config {
    volumes {
      enabled = true
    }
  }
}

plugin "raw_exec" {
  config {
    enabled = true
  }
}

acl {
  enabled = true
}

server {
  default_scheduler_config {
    # default "binpack" is annoying esp. for self-hosted clusters
    scheduler_algorithm             = "spread"

    # we use `memory` and `memory_max` in our `project.nomad` template
    memory_oversubscription_enabled = true
  }
}
