# AWS Vars

variable "aws_user" {
  default = "centos"
}

variable "aws_region" {
  default = "us-west-2"
}

variable "aws_instance_type" {
  default = "t2.micro"
}

variable "aws_image" {
  default = "ami-d2c924b2"
}

variable "keypair" {
  description = "AWS Keypair"
  default = "main"
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
  default = "f1-micro"
}

variable "gcp_image" {
  default = "centos-7-v20170426"
}
