resource "google_compute_firewall" "dns" {
  name    = "dns"
  network = "${data.terraform_remote_state.network.gcp_network}"

  allow {
    protocol = "tcp"
    ports    = ["53"]
  }

  allow {
    protocol = "udp"
    ports    = ["53"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "consul-servers" {
  name    = "consul-servers"
  network = "${data.terraform_remote_state.network.gcp_network}"

  allow {
    protocol = "tcp"
    ports    = ["8300-8302", "8500"]
  }

  allow {
    protocol = "udp"
    ports    = ["8301-8302"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["consul-servers"]
}
