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

resource "google_compute_firewall" "consul-clients" {
  name    = "consul-clients"
  network = "${data.terraform_remote_state.network.gcp_network}"

  allow {
    protocol = "tcp"
    ports    = ["8300-8301", "8500"]
  }

  allow {
    protocol = "udp"
    ports    = ["8301"]
  }

  source_tags   = ["consul-servers"]
  target_tags   = ["consul-clients"]
}

resource "google_compute_firewall" "traefik" {
  name    = "traefik"
  network = "${data.terraform_remote_state.network.gcp_network}"

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["traefik"]
}

resource "google_compute_firewall" "traefik-adm" {
  name    = "traefik-adm"
  network = "${data.terraform_remote_state.network.gcp_network}"

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }

  source_tags = ["bastion"]
  target_tags   = ["traefik"]
}
