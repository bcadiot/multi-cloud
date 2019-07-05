provider "google" {
  version = "~> 2.10"
  region  = var.region_gcp
}

provider "google-beta" {
  version = "~> 2.10"
  region  = var.region_gcp
}

provider "aws" {
  version = "~> 2.16"
  region  = var.region_aws
}

