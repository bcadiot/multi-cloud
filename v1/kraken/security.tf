resource "google_compute_firewall" "kraken" {
  name    = "kraken"
  network = "${data.terraform_remote_state.network.gcp_network}"

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  // target_tags   = ["traefik"]
}
