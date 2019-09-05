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

  metadata_startup_script = "${element(data.template_file.gcp_bootstrap_consul.*.rendered, count.index)}"
}

data "template_file" "gcp_bootstrap_consul" {
  count = 3
  template = "${file("bootstrap_consul.tpl")}"

  vars {
    domain = "${var.domain}"
    zone = "$(curl http://metadata.google.internal/computeMetadata/v1/instance/zone -H \"Metadata-Flavor: Google\" | cut -d\"/\" -f4)"
    datacenter = "$(echo $${ZONE} | cut -d\"-\" -f1)-$(echo $${ZONE} | cut -d\"-\" -f2)"
    output_ip = "$(curl http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip -H \"Metadata-Flavor: Google\")"
    consul_version = "0.9.2"
    join = "\"retry_join\": [\"provider=gce tag_value=consul-servers\"]"
    node_name = "server-gcp-consul-${count.index + 1}"
  }
}
