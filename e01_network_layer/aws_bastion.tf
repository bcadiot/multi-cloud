# Bastion specs

resource "aws_instance" "bastion" {
  instance_type = "${var.aws_instance_type}"
  ami = "${var.aws_image}"
  key_name = "${var.keypair}"

  vpc_security_group_ids = ["${aws_security_group.bastion.id}"]
  subnet_id = "${element(aws_subnet.nomad.*.id, count.index)}"
  associate_public_ip_address = true
}

# NAT GW specs

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.nomad.id}"
}
