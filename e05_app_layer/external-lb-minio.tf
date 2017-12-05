resource "fastly_service_v1" "minio" {
  name = "minio-fastly"

  domain {
    name    = "${var.minio-subdomain}.${var.domain}"
    comment = "${var.minio-subdomain}"
  }

  backend {
    address = "${data.terraform_remote_state.consul.gcp_traefik_public_ips.0}"
    name    = "GCP LB 1 hosting"
    port    = 80
    error_threshold = 5
    healthcheck = "miniohealth"
  }

  backend {
    address = "${data.terraform_remote_state.consul.gcp_traefik_public_ips.1}"
    name    = "GCP LB 2 hosting"
    port    = 80
    error_threshold = 5
    healthcheck = "miniohealth"
  }

  backend {
    address = "${data.terraform_remote_state.consul.aws_traefik_public_ips.0}"
    name    = "AWS LB 1 hosting"
    port    = 80
    error_threshold = 5
    healthcheck = "miniohealth"
  }

  backend {
    address = "${data.terraform_remote_state.consul.aws_traefik_public_ips.1}"
    name    = "AWS LB 2 hosting"
    port    = 80
    error_threshold = 5
    healthcheck = "miniohealth"
  }

  healthcheck {
    method         = "GET"
    host           = "${var.minio-subdomain}.${var.domain}"
    check_interval = "5000"
    timeout        = "5000"
    path           = "/minio/"
    name           = "miniohealth"
  }

  cache_setting {
    name   = "nocache"
    action = "pass"
  }

  force_destroy = true
}
