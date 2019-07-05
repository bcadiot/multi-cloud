# AWS Vars

variable "region_aws" {
  default = "eu-west-3"
}

variable "aws_cidr" {
  default = "172.30.3.0/24"
}

# GCP Vars

variable "region_gcp" {
  default = "europe-west1"
}

variable "gcp_cidr" {
  default = "172.27.3.0/24"
}
