# Commons

variable "private_key_path" {
  default = "~/.ssh/id_rsa"
}

# GCP Vars

variable "gcp_user" {
  default = "bcadiot"
}

variable "gcp_region" {
  default = "europe-west1"
}

variable "az_gcp" {
  default = [
      "b",
      "c",
      "d"
    ]
}

variable "gcp_instance_type" {
  default = "n1-standard-1"
}

variable "gcp_image" {
  default = "centos-7-v20170426"
}
