# Local LB

resource "aws_instance" "traefik" {
  count = 2
  instance_type = "${var.aws_instance_type}"
  ami = "${var.aws_image}"
  key_name = "${var.keypair}"
  // iam_instance_profile = "${aws_iam_instance_profile.consul.id}"
  iam_instance_profile = "ec2_describe_instances"

  vpc_security_group_ids = ["${aws_security_group.traefik.id}", "${aws_security_group.traefik_adm.id}", "${aws_security_group.consul_clients.id}"]
  subnet_id = "${element(data.terraform_remote_state.network.aws_pub_subnet, count.index + 1)}"
  associate_public_ip_address = true

  user_data = "${element(data.template_file.aws_traefik_bootstrap.*.rendered, count.index)}"

  tags {
    Name = "server-aws-traefik-${count.index + 1}"
    Consul = "client"
  }

  depends_on = ["aws_instance.consul"]
}

data "template_file" "aws_traefik_bootstrap" {
  count = 2
  template = "${file("bootstrap_traefik.tpl")}"

  vars {
    domain = "${var.domain}"
    zone = "$(curl http://169.254.169.254/latest/meta-data/placement/availability-zone)"
    datacenter = "$(echo $${ZONE} | sed 's/.$//')"
    output_ip = "$(curl http://169.254.169.254/latest/meta-data/local-ipv4)"
    consul_version = "0.9.2"
    traefik_version = "1.3.2"
    join = "\"retry_join\": [\"provider=aws tag_key=Consul tag_value=server\"]"
    node_name = "server-aws-traefik-${count.index + 1}"
  }
}
