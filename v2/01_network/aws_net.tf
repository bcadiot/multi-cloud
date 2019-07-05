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

// # Routing specs

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

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

