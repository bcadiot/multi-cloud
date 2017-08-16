resource "aws_instance" "consul" {
  count = 3
  instance_type = "${var.aws_instance_type}"
  ami = "${var.aws_image}"
  key_name = "${var.keypair}"
  // iam_instance_profile = "${aws_iam_instance_profile.consul.id}"

  vpc_security_group_ids = ["${aws_security_group.consul_servers.id}"]
  subnet_id = "${element(data.terraform_remote_state.network.aws_priv_subnet, count.index)}"
  associate_public_ip_address = false

  user_data = "${data.template_file.aws_bootstrap.rendered}"

  tags {
    Name = "server-aws-nomad-${count.index + 1}"
  }

  depends_on = ["google_compute_instance.consul"]
}

data "template_file" "aws_bootstrap" {
  template = "${file("aws_bootstrap.tpl")}"

  vars {
    tag_key = "consul"
    tag_value = "server"
    join_wan = "${join(", ", formatlist("\"%s\"", google_compute_instance.consul.*.network_interface.0.address))}"
  }
}
