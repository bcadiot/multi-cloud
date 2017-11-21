resource "google_compute_instance" "datanode" {
  count        = 2
  name         = "server-gcp-datanode-clients-${count.index + 1}"
  machine_type = "${var.gcp_instance_type}"
  zone         = "${var.gcp_region}-${element(var.az_gcp, count.index)}"

  boot_disk {
    initialize_params {
      image = "${var.gcp_image}"
    }
  }

  attached_disk {
    source = "${element(google_compute_disk.datanode-disks.*.self_link, count.index)}"
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  tags = ["nomad-clients", "consul-clients", "minio"]

  network_interface {
    subnetwork = "${data.terraform_remote_state.network.gcp_priv_subnet}"
  }

  service_account {
    scopes = [
        "https://www.googleapis.com/auth/compute.readonly"
      ]
  }

  metadata_startup_script = "${element(data.template_file.gcp_bootstrap_nomad_client.*.rendered, count.index)}"
}

resource "google_compute_disk" "datanode-disks" {
  count = 2
  type  = "pd-standard"
  name  = "datanode-disks-${count.index + 1}"
  zone  = "${var.gcp_region}-${element(var.az_gcp, count.index)}"
  size = 50
}

data "template_file" "gcp_bootstrap_nomad_client" {
  count = 2
  template = "${file("../e03_scheduler_layer/bootstrap_nomad.tpl")}"

  vars {
    zone = "$(curl http://metadata.google.internal/computeMetadata/v1/instance/zone -H \"Metadata-Flavor: Google\" | cut -d\"/\" -f4)"
    region = "$(echo $${ZONE} | cut -d\"-\" -f1)"
    datacenter = "$(echo $${ZONE} | cut -d\"-\" -f1)-$(echo $${ZONE} | cut -d\"-\" -f2)"
    output_ip = "$(curl http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip -H \"Metadata-Flavor: Google\")"
    nomad_version = "0.6.2"
    consul_version = "0.9.2"
    node_type = "client"
    dns1 = "${data.terraform_remote_state.consul.gcp_consul_ips.0}"
    dns2 = "${data.terraform_remote_state.consul.gcp_consul_ips.1}"
    dns3 = "${data.terraform_remote_state.consul.gcp_consul_ips.2}"
    join = "\"retry_join\": [\"provider=gce tag_value=consul-servers\"]"
    persistent_disk = "/dev/sdb"
    cloud = "gcp"
    node_class = "data"
    node_name = "server-gcp-datanode-clients-${count.index + 1}"
  }
}
