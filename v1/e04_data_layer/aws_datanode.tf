resource "aws_instance" "datanode" {
  count = 2
  instance_type = "${var.aws_instance_type}"
  ami = "${var.aws_image}"
  key_name = "${var.keypair}"
  iam_instance_profile = "ec2_describe_instances"

  vpc_security_group_ids = ["${aws_security_group.minio.id}", "${data.terraform_remote_state.consul.aws_consul_client_sg}", "${data.terraform_remote_state.nomad.aws_nomad_client_sg}"]
  subnet_id = "${element(data.terraform_remote_state.network.aws_priv_subnet, count.index)}"
  associate_public_ip_address = false

  user_data = "${element(data.template_file.aws_bootstrap_nomad_clients.*.rendered, count.index)}"

  ebs_block_device {
    device_name = "/dev/xvdf"
    volume_size = "50"
  }

  tags {
    Name = "server-aws-datanode-${count.index + 1}"
    Consul = "client"
  }
}

data "template_file" "aws_bootstrap_nomad_clients" {
  count = 2
  template = "${file("../e03_scheduler_layer/bootstrap_nomad.tpl")}"

  vars {
    zone = "$(curl http://169.254.169.254/latest/meta-data/placement/availability-zone)"
    region = "$(echo $${ZONE} | cut -d\"-\" -f1)"
    datacenter = "$(echo $${ZONE} | sed 's/.$//')"
    output_ip = "$(curl http://169.254.169.254/latest/meta-data/local-ipv4)"
    nomad_version = "0.6.2"
    consul_version = "0.9.2"
    node_type = "client"
    join = "\"retry_join\": [\"provider=aws tag_key=Consul tag_value=server\"]"
    dns1 = "${data.terraform_remote_state.consul.aws_consul_ips.0}"
    dns2 = "${data.terraform_remote_state.consul.aws_consul_ips.1}"
    dns3 = "${data.terraform_remote_state.consul.aws_consul_ips.2}"
    persistent_disk = "/dev/xvdf"
    cloud = "aws"
    node_class = "data"
    node_name = "server-aws-datanode-${count.index + 1}"
  }
}
