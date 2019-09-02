# VPC specs

resource "google_compute_network" "main" {
  name                    = "main"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "subnet" {
  name          = "subnet"
  ip_cidr_range = var.gcp_cidr
  network       = google_compute_network.main.self_link
}
