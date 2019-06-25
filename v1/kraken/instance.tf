resource "google_compute_instance" "kraken" {
  name         = "server-gcp-kraken"
  machine_type = "${var.gcp_instance_type}"
  zone         = "${var.gcp_region}-${element(var.az_gcp, 0)}"

  boot_disk {
    initialize_params {
      image = "${var.gcp_image}"
    }
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  tags = ["kraken"]

  network_interface {
    subnetwork = "${data.terraform_remote_state.network.gcp_pub_subnet}"
    access_config {
      // Auto generate
    }
  }

  metadata_startup_script = "${data.template_file.bootstrap.rendered}"

  connection {
    bastion_host = "${data.terraform_remote_state.network.gcp_bastion_ip[0]}"
    bastion_user = "${var.gcp_user}"
    bastion_private_key = "${file("${var.private_key_path}")}"

    user = "${var.gcp_user}"
    host = "${google_compute_instance.kraken.network_interface.0.address}"
    timeout = "60s"
    private_key = "${file("${var.private_key_path}")}"
    agent = false
  }

  provisioner "local-exec" {
    command = "rm -rf app/node_modules && rm -rf app/.meteor/local && tar zcvf kraken.tgz app/"
  }

  provisioner "file" {
    source      = "kraken.tgz"
    destination = "/tmp/kraken.tgz"
  }
}

data "template_file" "bootstrap" {
  template = "${file("bootstrap.tpl")}"

  vars {
    dns1 = "${data.terraform_remote_state.consul.gcp_consul_ips.0}"
    dns2 = "${data.terraform_remote_state.consul.gcp_consul_ips.1}"
    dns3 = "${data.terraform_remote_state.consul.gcp_consul_ips.2}"
    cloud = "gcp"
  }
}
