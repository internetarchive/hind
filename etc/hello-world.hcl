# Minimal basic project using only GitLab CI/CD std. variables
# Run like:   nomad run hello-world.hcl

# Variables used below and their defaults if not set externally
variables {
  # These all pass through from GitLab [build] phase.
  # Some defaults filled in w/ example repo "bai" in group "internetarchive"
  # (but all 7 get replaced during normal GitLab CI/CD from CI/CD variables).
  CI_REGISTRY = "registry.gitlab.com"                       # registry hostname
  CI_REGISTRY_IMAGE = "registry.gitlab.com/internetarchive/bai"  # registry image location
  CI_COMMIT_REF_SLUG = "main"                               # branch name, slugged
  CI_COMMIT_SHA = "latest"                                  # repo's commit for current pipline
  CI_PROJECT_PATH_SLUG = "internetarchive-bai"              # repo and group it is part of, slugged
  CI_REGISTRY_USER = ""                                     # set for each pipeline and ..
  CI_REGISTRY_PASSWORD = ""                                 # .. allows pull from private registry

  # Switch this, locally edit your /etc/hosts, or otherwise.  as is, webapp will appear at:
  #   https://internetarchive-bai-main.x.archive.org/
  BASE_DOMAIN = "x.archive.org"
}

# NOTE: job "hello-world" should really be job "${local.job_names[0]}"
#       but `job ".." {` can't interpolate vars/locals yet in HCL v2.
locals {
  job_names = [ "${var.CI_PROJECT_PATH_SLUG}-${var.CI_COMMIT_REF_SLUG}" ]
}

job "hello-world" {
  datacenters = ["dc1"]
  group "group" {
    network {
      port "http" {
        to = 5000
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
        image = "${var.CI_REGISTRY_IMAGE}/${var.CI_COMMIT_REF_SLUG}:${var.CI_COMMIT_SHA}"

        ports = [ "http" ]

        auth {
          username = "${var.CI_REGISTRY_USER}"
          password = "${var.CI_REGISTRY_PASSWORD}"
        }
      }
    }
  }
}
