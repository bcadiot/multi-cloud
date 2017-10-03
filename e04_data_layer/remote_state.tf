data "terraform_remote_state" "network" {
  backend = "local"

  config {
    path = "../e01_network_layer/terraform.tfstate"
  }
}

data "terraform_remote_state" "consul" {
  backend = "local"

  config {
    path = "../e02_services_lb_layer/terraform.tfstate"
  }
}

data "terraform_remote_state" "nomad" {
  backend = "local"

  config {
    path = "../e03_scheduler_layer/terraform.tfstate"
  }
}
