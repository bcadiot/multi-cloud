# Security Groups Configuration

resource "aws_security_group" "nomad_servers" {
  vpc_id      = "${data.terraform_remote_state.network.aws_vpc}"
  name        = "nomad_servers_sg"

  # ICMP
  ingress {
    protocol  = "icmp"
    from_port = 8
    to_port   = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH
  ingress {
    protocol  = "tcp"
    from_port = 22
    to_port   = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Nomad RPC + Serf
  ingress {
    protocol  = "tcp"
    from_port = 4646
    to_port   = 4648
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Nomad Serf (UDP)
  ingress {
    protocol  = "udp"
    from_port = 4648
    to_port   = 4648
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "nomad_clients" {
  vpc_id      = "${data.terraform_remote_state.network.aws_vpc}"
  name        = "nomad_clients_sg"

  # ICMP
  ingress {
    protocol  = "icmp"
    from_port = 8
    to_port   = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH
  ingress {
    protocol  = "tcp"
    from_port = 22
    to_port   = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Nomad RPC + Serf
  ingress {
    protocol  = "tcp"
    from_port = 4646
    to_port   = 4647
    security_groups = ["${aws_security_group.nomad_servers.id}"]
    self = true
  }

  # Nomad Apps TCP
  ingress {
    protocol  = "tcp"
    from_port = 20000
    to_port   = 60000
    security_groups = ["${data.terraform_remote_state.consul.aws_traefik_sg}"]
    self = true
  }

  # Nomad Apps UDP
  ingress {
    protocol  = "udp"
    from_port = 20000
    to_port   = 60000
    security_groups = ["${data.terraform_remote_state.consul.aws_traefik_sg}"]
    self = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
