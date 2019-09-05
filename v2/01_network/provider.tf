provider "google" {
  version = "~> 2.10"
  region  = var.gcp_region
}

provider "aws" {
  version = "~> 2.16"
  region  = var.aws_region
}

