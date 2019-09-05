resource "fastly_service_v1" "app" {
  name = "app-fastly"

  domain {
    name    = "${var.app-subdomain}.${var.domain}"
    comment = "${var.app-subdomain}"
  }

  backend {
    address = "${data.terraform_remote_state.consul.gcp_traefik_public_ips.0}"
    name    = "GCP LB 1 hosting"
    port    = 80
    error_threshold = 5
    healthcheck = "apphealth"
  }

  backend {
    address = "${data.terraform_remote_state.consul.gcp_traefik_public_ips.1}"
    name    = "GCP LB 2 hosting"
    port    = 80
    error_threshold = 5
    healthcheck = "apphealth"
  }

  backend {
    address = "${data.terraform_remote_state.consul.aws_traefik_public_ips.0}"
    name    = "AWS LB 1 hosting"
    port    = 80
    error_threshold = 5
    healthcheck = "apphealth"
  }

  backend {
    address = "${data.terraform_remote_state.consul.aws_traefik_public_ips.1}"
    name    = "AWS LB 2 hosting"
    port    = 80
    error_threshold = 5
    healthcheck = "apphealth"
  }

  healthcheck {
    method         = "GET"
    host           = "${var.app-subdomain}.${var.domain}"
    check_interval = "5000"
    timeout = "5000"
    path           = "/img/favicon.png"
    name           = "apphealth"
  }

  cache_setting {
    name   = "nocache"
    action = "pass"
  }

  force_destroy = true
}
