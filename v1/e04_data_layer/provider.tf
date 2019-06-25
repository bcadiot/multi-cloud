provider "google" {
  region = "${var.gcp_region}"
}

provider "aws" {
  region = "${var.aws_region}"
}
