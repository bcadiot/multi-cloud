resource "google_compute_instance" "nomad_servers" {
  count        = 3
  name         = "server-gcp-nomad-servers-${count.index + 1}"
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

  tags = ["nomad-servers", "consul-clients"]

  network_interface {
    subnetwork = "${data.terraform_remote_state.network.gcp_priv_subnet}"
  }

  service_account {
    scopes = [
        "https://www.googleapis.com/auth/compute.readonly"
      ]
  }

  metadata_startup_script = "${data.template_file.gcp_bootstrap_nomad_server.rendered}"
}

data "template_file" "gcp_bootstrap_nomad_server" {
  template = "${file("bootstrap_nomad.tpl")}"

  vars {
    zone = "$(curl http://metadata.google.internal/computeMetadata/v1/instance/zone -H \"Metadata-Flavor: Google\" | cut -d\"/\" -f4)"
    region = "$(echo $${ZONE} | cut -d\"-\" -f1)"
    datacenter = "$(echo $${ZONE} | cut -d\"-\" -f1)-$(echo $${ZONE} | cut -d\"-\" -f2)"
    output_ip = "$(curl http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip -H \"Metadata-Flavor: Google\")"
    nomad_version = "0.6.2"
    consul_version = "0.9.2"
    node_type = "server"
    join = "\"retry_join\": [\"provider=gce tag_value=consul-servers\"]"
  }
}

resource "google_compute_instance" "nomad_clients" {
  count        = 3
  name         = "server-gcp-nomad-clients-${count.index + 1}"
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

  tags = ["nomad-clients", "consul-clients"]

  network_interface {
    subnetwork = "${data.terraform_remote_state.network.gcp_priv_subnet}"
  }

  service_account {
    scopes = [
        "https://www.googleapis.com/auth/compute.readonly"
      ]
  }

  metadata_startup_script = "${data.template_file.gcp_bootstrap_nomad_client.rendered}"

  depends_on = ["google_compute_instance.nomad_servers"]
}

data "template_file" "gcp_bootstrap_nomad_client" {
  template = "${file("bootstrap_nomad.tpl")}"

  vars {
    zone = "$(curl http://metadata.google.internal/computeMetadata/v1/instance/zone -H \"Metadata-Flavor: Google\" | cut -d\"/\" -f4)"
    region = "$(echo $${ZONE} | cut -d\"-\" -f1)"
    datacenter = "$(echo $${ZONE} | cut -d\"-\" -f1)-$(echo $${ZONE} | cut -d\"-\" -f2)"
    output_ip = "$(curl http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip -H \"Metadata-Flavor: Google\")"
    nomad_version = "0.6.2"
    consul_version = "0.9.2"
    node_type = "client"
    join = "\"retry_join\": [\"provider=gce tag_value=consul-servers\"]"
  }
}
