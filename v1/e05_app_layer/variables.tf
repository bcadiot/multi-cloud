# Commons

variable "private_key_path" {
  default = "~/.ssh/id_rsa"
}

# GCP Vars

variable "gcp_user" {
  default = "bcadiot"
}

# Fastly vars

variable "domain" {
  default = "cadiot.fr"
}

variable "minio-subdomain" {
  default = "minio-test"
}

variable "app-subdomain" {
  default = "app-test"
}
