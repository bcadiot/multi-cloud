# VPC specs

resource "aws_vpc" "nomad" {
  cidr_block = "172.30.3.0/24"
}

resource "aws_subnet" "nomad" {
  count = 3

  cidr_block        = "${cidrsubnet(aws_vpc.nomad.cidr_block, 2, count.index)}"
  availability_zone = "${var.region_aws}${element(var.az_aws, count.index)}"
  vpc_id            = "${aws_vpc.nomad.id}"
}

# VPN specs

resource "aws_vpn_gateway" "vpn_gateway" {
  vpc_id = "${aws_vpc.nomad.id}"
}

resource "aws_customer_gateway" "customer_gateway" {
  bgp_asn    = "${var.bgp_gcp}"
  ip_address = "${google_compute_address.vpn_static_ip.address}"
  type       = "ipsec.1"
}

resource "aws_vpn_connection" "nomad" {
  vpn_gateway_id      = "${aws_vpn_gateway.vpn_gateway.id}"
  customer_gateway_id = "${aws_customer_gateway.customer_gateway.id}"
  type                = "ipsec.1"
}

// # Routing specs

resource "aws_route_table" "pub" {
  vpc_id = "${aws_vpc.nomad.id}"

  propagating_vgws = ["${aws_vpn_gateway.vpn_gateway.id}"]

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }
}

resource "aws_route_table_association" "pub" {
  count = 3

  subnet_id      = "${element(aws_subnet.nomad.*.id, count.index)}"
  route_table_id = "${aws_route_table.pub.id}"
}
