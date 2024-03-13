server = true
advertise_addr = "{{ GetInterfaceIP \"eth0\" }}"

ui_config {
  enabled = true
}

limits {
  # default of 200 is too low for clusters with 200+ deploys
  http_max_conns_per_client = 32767
}

# setup for 2+ VMs to have their consul daemons be able to talk to each other
# echo -n THIS-GETS-REPLACED-IT-DOES-RILLY |base64
encrypt = "VEhJUy1HRVRTLVJFUExBQ0VELUlULURPRVMtUklMTFk="
