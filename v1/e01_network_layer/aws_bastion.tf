# Bastion specs

resource "aws_instance" "bastion" {
  instance_type = "${var.aws_instance_type}"
  ami = "${var.aws_image}"
  key_name = "${var.keypair}"

  vpc_security_group_ids = ["${aws_security_group.bastion.id}"]
  subnet_id = "${element(aws_subnet.pub.*.id, count.index)}"
  associate_public_ip_address = true

  user_data = "${data.template_file.aws_bootstrap.rendered}"
}

data "template_file" "aws_bootstrap" {
  template = "${file("bootstrap_aws_bastion.tpl")}"

  vars {
    private_key = "${file(var.private_key_path)}"
  }
}

# NAT GW specs

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.nomad.id}"
}

resource "aws_nat_gateway" "gw" {
  allocation_id = "${aws_eip.nat.id}"
  subnet_id     = "${aws_subnet.pub.0.id}"

  depends_on = ["aws_internet_gateway.gw"]
}

resource "aws_eip" "nat" {
  vpc      = true
}
