# Routing specs
# VPN specs

resource "aws_vpn_gateway" "vpn_gateway" {
  vpc_id = var.aws_vpc
}

resource "aws_customer_gateway" "customer_gateway_1" {
  bgp_asn    = google_compute_router.main.bgp[0].asn
  ip_address = google_compute_ha_vpn_gateway.target_gateway.vpn_interfaces[0].ip_address
  type       = "ipsec.1"
}

resource "aws_customer_gateway" "customer_gateway_2" {
  bgp_asn    = google_compute_router.main.bgp[0].asn
  ip_address = google_compute_ha_vpn_gateway.target_gateway.vpn_interfaces[1].ip_address
  type       = "ipsec.1"
}

resource "aws_vpn_connection" "cx_1" {
  vpn_gateway_id      = aws_vpn_gateway.vpn_gateway.id
  customer_gateway_id = aws_customer_gateway.customer_gateway_1.id
  type                = "ipsec.1"
}

resource "aws_vpn_connection" "cx_2" {
  vpn_gateway_id      = aws_vpn_gateway.vpn_gateway.id
  customer_gateway_id = aws_customer_gateway.customer_gateway_2.id
  type                = "ipsec.1"
}

resource "aws_route_table" "main" {
  vpc_id = var.aws_vpc

  propagating_vgws = [aws_vpn_gateway.vpn_gateway.id]

  # route {
  #   cidr_block = "35.199.192.0/19"
  #   gateway_id = "${aws_vpn_gateway.vpn_gateway.id}"
  # }

  #   route {
  #     cidr_block = "0.0.0.0/0"
  #     gateway_id = aws_internet_gateway.gw.id
  #   }
}

resource "aws_route_table_association" "main" {
  count = 3

  subnet_id      = element(var.aws_subnets, count.index)
  route_table_id = aws_route_table.main.id
}

