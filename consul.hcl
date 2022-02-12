server = true
advertise_addr = "{{ GetInterfaceIP \"eth0\" }}"
bootstrap_expect = 1

ui_config {
  enabled = true
}
