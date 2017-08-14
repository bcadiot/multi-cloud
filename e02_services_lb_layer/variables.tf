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
  default = "f1-micro"
}

variable "gcp_image" {
  default = "centos-7-v20170426"
}
