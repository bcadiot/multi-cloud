resource "google_compute_firewall" "minio" {
  name    = "minio"
  network = "${data.terraform_remote_state.network.gcp_network}"

  allow {
    protocol = "tcp"
    ports    = ["9000"]
  }

  source_ranges = ["172.27.3.0/24", "172.30.3.0/24"]
  target_tags   = ["minio"]
}
