# Local LB

resource "google_compute_instance" "traefik" {
  count        = 2
  name         = "server-gcp-traefik-${count.index + 1}"
  machine_type = "${var.gcp_instance_type}"
  zone         = "${var.gcp_region}-${element(var.az_gcp, count.index + 1)}"

  boot_disk {
    initialize_params {
      image = "${var.gcp_image}"
    }
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  tags = ["traefik", "consul-clients"]

  network_interface {
    subnetwork = "${data.terraform_remote_state.network.gcp_pub_subnet}"
    access_config {
      // Auto generate
    }
  }

  service_account {
    scopes = [
        "https://www.googleapis.com/auth/compute.readonly"
      ]
  }

  metadata_startup_script = "${data.template_file.gcp_traefik_bootstrap.rendered}"
}

data "template_file" "gcp_traefik_bootstrap" {
  template = "${file("bootstrap_traefik.tpl")}"

  vars {
    domain = "${var.domain}"
    zone = "$(curl http://metadata.google.internal/computeMetadata/v1/instance/zone -H \"Metadata-Flavor: Google\" | cut -d\"/\" -f4)"
    datacenter = "$(echo $${ZONE} | cut -d\"-\" -f1)-$(echo $${ZONE} | cut -d\"-\" -f2)"
    output_ip = "$(curl http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip -H \"Metadata-Flavor: Google\")"
    consul_version = "0.9.2"
    traefik_version = "1.3.2"
    join = "\"retry_join\": [\"provider=gce tag_value=consul-servers\"]"
  }
}
