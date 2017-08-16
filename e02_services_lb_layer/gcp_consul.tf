resource "google_compute_instance" "consul" {
  count        = 3
  name         = "server-gcp-consul-${count.index + 1}"
  machine_type = "${var.gcp_instance_type}"
  zone         = "${var.gcp_region}-${element(var.az_gcp, count.index)}"

  boot_disk {
    initialize_params {
      image = "${var.gcp_image}"
    }
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  tags = ["consul-servers"]

  network_interface {
    subnetwork = "${data.terraform_remote_state.network.gcp_priv_subnet}"
  }

  service_account {
    scopes = [
        "https://www.googleapis.com/auth/compute.readonly"
      ]
  }

  metadata_startup_script = "${data.template_file.gcp_bootstrap.rendered}"
}

data "template_file" "gcp_bootstrap" {
  template = "${file("gcp_bootstrap.tpl")}"

  vars {
    node_type = "server"
    tag = "consul-servers"
  }
}
