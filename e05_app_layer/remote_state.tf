data "terraform_remote_state" "consul" {
  backend = "local"

  config {
    path = "../e02_services_lb_layer/terraform.tfstate"
  }
}
