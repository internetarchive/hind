# Minimal basic project, using env variables, with defaults if not set.
# Run like:   nomad run hello-world.hcl

# Variables used below and their defaults if not set externally
variables {
  # These all pass through from the github action, or gitlab's CI/CD variables.
  # Some defaults filled in w/ example repo "hello-js" in group "internetarchive"
  # (but all get replaced during normal GitLab CI/CD from CI/CD variables).
  CI_REGISTRY_IMAGE = "ghcr.io/internetarchive/hello-js"    # registry image location
  CI_COMMIT_REF_SLUG = "main"                               # branch name, slugged
  CI_COMMIT_SHA = "main"                                    # GH: registry image tag; GL: commit sha
  CI_PROJECT_PATH_SLUG = "internetarchive-hello-js"         # repo and group it is part of, slugged
  CI_REGISTRY_USER = ""                                     # set for each pipeline and ..
  CI_REGISTRY_PASSWORD = ""                                 # .. allows pull from private registry

  # Switch this, locally edit your /etc/hosts, or otherwise.  as is, webapp will appear at:
  #   https://internetarchive-hello-js-main.x.archive.org/
  BASE_DOMAIN = "x.archive.org"
}

# NOTE: job "hello-world" should really be job "${local.job_names[0]}"
#       but `job ".." {` can't interpolate vars/locals yet in HCL v2.
locals {
  job_names = [ "${var.CI_PROJECT_PATH_SLUG}-${var.CI_COMMIT_REF_SLUG}" ]
  network_mode = "${attr.kernel.name}" != "darwin" ? "bridge" : "host"
  port = "${attr.kernel.name}" != "darwin" ? 5000 : 5555
}

job "hello-world" {
  datacenters = ["dc1"]
  group "group" {
    network {
      port "http" {
        to = local.port
      }
    }
    service {
      name = local.job_names[0]
      tags = ["https://${var.CI_PROJECT_PATH_SLUG}-${var.CI_COMMIT_REF_SLUG}.${var.BASE_DOMAIN}"]
      port = "http"
      check {
        type     = "http"
        port     = "http"
        path     = "/"
        interval = "10s"
        timeout  = "2s"
      }
    }
    task "http" {
      driver = "podman"

      config {
        network_mode = local.network_mode
        image = "${var.CI_REGISTRY_IMAGE}:${var.CI_COMMIT_SHA}"

        ports = [ "http" ]

        auth {
          username = "${var.CI_REGISTRY_USER}"
          password = "${var.CI_REGISTRY_PASSWORD}"
        }
      }
    }
  }
}
