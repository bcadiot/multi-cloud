
resource "null_resource" "deploy" {
  connection {
    bastion_host = "${data.terraform_remote_state.network.gcp_bastion_ip[0]}"
    bastion_user = "${var.gcp_user}"
    bastion_private_key = "${file("${var.private_key_path}")}"

    host = "${data.terraform_remote_state.nomad.gcp_nomad_servers_ips[0]}"
    user = "${var.gcp_user}"
    timeout = "60s"
    private_key = "${file("${var.private_key_path}")}"
    agent = false
  }

  # Deploy Minio AWS
  provisioner "file" {
    source      = "../e04_data_layer/app/minio-aws.nomad"
    destination = "/tmp/minio-aws.nomad"
  }

  # Deploy Minio GCP
  provisioner "file" {
    source      = "../e04_data_layer/app/minio-gcp.nomad"
    destination = "/tmp/minio-gcp.nomad"
  }

  # Deploy Consul Query
  provisioner "file" {
    source      = "files/storage-query.json"
    destination = "/tmp/storage-query.json"
  }

  # Deploy Minio Files
  provisioner "file" {
    source      = "files/bucket/"
    destination = "/tmp/"
  }

  # Deploy App AWS
  provisioner "file" {
    source      = "files/app-aws.nomad"
    destination = "/tmp/app-aws.nomad"
  }

  # Deploy App GCP
  provisioner "file" {
    source      = "files/app-gcp.nomad"
    destination = "/tmp/app-gcp.nomad"
  }

  # Provision Minio Nodes
  provisioner "remote-exec" {
    inline = [
      "sleep 180",
      "export NOMAD_ADDR=http://${data.terraform_remote_state.nomad.gcp_nomad_servers_ips[0]}:4646",
      "nomad run /tmp/minio-aws.nomad",
      "nomad run /tmp/minio-gcp.nomad"
    ]
  }

  # Provision Consul Query
  provisioner "remote-exec" {
    inline = [
      "sleep 20",
      "cd /tmp/",
      "curl --request POST --data @storage-query.json http://${data.terraform_remote_state.consul.gcp_consul_ips[0]}:8500/v1/query"
    ]
  }

  # Configure Minio
  provisioner "remote-exec" {
    inline = [
      # Récupération du client et connexion au cluster
      "wget https://dl.minio.io/client/mc/release/linux-amd64/mc",
      "chmod +x mc",
      "./mc config host add myminio http://storage-object-minio.query.consul:9000 AKIAIOSFODNN7EXAMPLE wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",

      # Création du bucket et changement de la policy par défaut
      "./mc mb myminio/minio-store",
      "sleep 60",
      "./mc policy public myminio/minio-store",

      # Copie des fichiers
      "./mc cp /tmp/*.png myminio/minio-store/"
    ]
  }

  # Provision App Nodes
  provisioner "remote-exec" {
    inline = [
      "sleep 60",
      "export NOMAD_ADDR=http://${data.terraform_remote_state.nomad.gcp_nomad_servers_ips[0]}:4646",
      "nomad run /tmp/app-aws.nomad",
      "nomad run /tmp/app-gcp.nomad"
    ]
  }
}
