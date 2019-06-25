provider "google" {
  region = "${var.region_gcp}"
}

provider "aws" {
  region = "${var.region_aws}"
}
