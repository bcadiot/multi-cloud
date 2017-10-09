resource "aws_instance" "nomad_servers" {
  count = 3
  instance_type = "${var.aws_instance_type}"
  ami = "${var.aws_image}"
  key_name = "${var.keypair}"
  iam_instance_profile = "ec2_describe_instances"

  vpc_security_group_ids = ["${aws_security_group.nomad_servers.id}", "${data.terraform_remote_state.consul.aws_consul_client_sg}"]
  subnet_id = "${element(data.terraform_remote_state.network.aws_priv_subnet, count.index)}"
  associate_public_ip_address = false

  user_data = "${data.template_file.aws_bootstrap_nomad_servers.rendered}"

  tags {
    Name = "server-aws-nomad-server-${count.index + 1}"
    Consul = "client"
  }
}

data "template_file" "aws_bootstrap_nomad_servers" {
  template = "${file("bootstrap_nomad.tpl")}"

  vars {
    zone = "$(curl http://169.254.169.254/latest/meta-data/placement/availability-zone)"
    region = "$(echo $${ZONE} | cut -d\"-\" -f1)"
    datacenter = "$(echo $${ZONE} | sed 's/.$//')"
    output_ip = "$(curl http://169.254.169.254/latest/meta-data/local-ipv4)"
    nomad_version = "0.6.2"
    consul_version = "0.9.2"
    node_type = "server"
    join = "\"retry_join\": [\"provider=aws tag_key=Consul tag_value=server\"]"
    dns1 = "${data.terraform_remote_state.consul.aws_consul_ips.0}"
    dns2 = "${data.terraform_remote_state.consul.aws_consul_ips.1}"
    dns3 = "${data.terraform_remote_state.consul.aws_consul_ips.2}"
    persistent_disk = ""
    cloud = "aws"
    node_class = "server"
  }
}

resource "aws_instance" "nomad_clients" {
  count = 3
  instance_type = "${var.aws_instance_type}"
  ami = "${var.aws_image}"
  key_name = "${var.keypair}"
  iam_instance_profile = "ec2_describe_instances"

  vpc_security_group_ids = ["${aws_security_group.nomad_clients.id}", "${data.terraform_remote_state.consul.aws_consul_client_sg}"]
  subnet_id = "${element(data.terraform_remote_state.network.aws_priv_subnet, count.index)}"
  associate_public_ip_address = false

  user_data = "${data.template_file.aws_bootstrap_nomad_clients.rendered}"

  tags {
    Name = "server-aws-nomad-client-${count.index + 1}"
    Consul = "client"
  }

  depends_on = ["aws_instance.nomad_servers"]
}

data "template_file" "aws_bootstrap_nomad_clients" {
  template = "${file("bootstrap_nomad.tpl")}"

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
    persistent_disk = ""
    cloud = "aws"
    node_class = "app"
  }
}
