data "terraform_remote_state" "network" {
  backend = "local"

  config {
    path = "../e01_network_layer/terraform.tfstate"
  }
}
