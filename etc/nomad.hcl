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
