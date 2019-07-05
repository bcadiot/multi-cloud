# VPC specs

resource "aws_vpc" "main" {
  cidr_block = var.aws_cidr

  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_subnet" "main" {
  count = 3

  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 3, count.index)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
  vpc_id            = aws_vpc.main.id
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

# VPN specs

resource "aws_vpn_gateway" "vpn_gateway" {
  vpc_id = aws_vpc.main.id
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

# Routing specs

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  propagating_vgws = [aws_vpn_gateway.vpn_gateway.id]

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "main" {
  count = 3

  subnet_id      = element(aws_subnet.main.*.id, count.index)
  route_table_id = aws_route_table.main.id
}

