# Bastion specs

resource "google_compute_instance" "bastion" {
  name         = "gcp-bastion"
  machine_type = "${var.gcp_instance_type}"
  zone         = "${var.region_gcp}-${element(var.az_gcp, count.index)}"
  can_ip_forward = true

  boot_disk {
    initialize_params {
      image = "${var.gcp_image}"
    }
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  tags = ["bastion"]

  network_interface {
    subnetwork = "${google_compute_subnetwork.pub.name}"
    access_config {
      // Auto generate
    }
  }

  metadata_startup_script = "${data.template_file.gcp_bootstrap.rendered}"
}

data "template_file" "gcp_bootstrap" {
  template = "${file("bootstrap_gcp_bastion.tpl")}"

  vars {
    private_key = "${file(var.private_key_path)}"
  }
}

# NAT GW specs

resource "google_compute_route" "nat_routing" {
  name        = "nat-routing"
  dest_range  = "0.0.0.0/0"
  network     = "${google_compute_network.nomad.name}"
  next_hop_instance_zone = "${var.region_gcp}-${element(var.az_gcp, count.index)}"
  next_hop_instance = "${google_compute_instance.bastion.name}"
  priority    = 800
  tags = ["nomad-servers", "nomad-clients", "consul-servers", "consul-clients"]
}
