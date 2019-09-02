module "network" {
  source = "./01_network"

  aws_region = "eu-west-3"
  gcp_region = "europe-west1"

  aws_cidr = "172.30.3.0/24"
  gcp_cidr = "172.27.3.0/24"
}

module "vpn" {
  source = "./02_vpn"

  aws_region = "eu-west-3"
  gcp_region = "europe-west1"

  aws_vpc     = module.network.aws_vpc
  aws_subnets = module.network.aws_subnets
  gcp_vpc     = module.network.gcp_vpc

  gcp_bgp = "65273"
}