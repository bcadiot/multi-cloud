resource "google_compute_firewall" "nomad-servers" {
  name    = "nomad-servers"
  network = "${data.terraform_remote_state.network.gcp_network}"

  allow {
    protocol = "tcp"
    ports    = ["4646-4648"]
  }

  allow {
    protocol = "udp"
    ports    = ["4648"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["nomad-servers"]
}

resource "google_compute_firewall" "nomad-clients" {
  name    = "nomad-clients"
  network = "${data.terraform_remote_state.network.gcp_network}"

  allow {
    protocol = "tcp"
    ports    = ["4646-4647"]
  }

  source_tags   = ["nomad-servers"]
  target_tags   = ["nomad-clients"]
}

resource "google_compute_firewall" "nomad-apps" {
  name    = "nomad-apps"
  network = "${data.terraform_remote_state.network.gcp_network}"

  allow {
    protocol = "tcp"
    ports    = ["20000-60000", "80", "443"]
  }

  allow {
    protocol = "udp"
    ports    = ["20000-60000"]
  }

  source_tags   = ["traefik"]
  target_tags   = ["nomad-clients"]
}
