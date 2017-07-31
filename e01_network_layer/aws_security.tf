resource "aws_security_group" "bastion" {
  vpc_id      = "${aws_vpc.nomad.id}"
  name        = "bastion_sg"

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

  ingress {
    protocol  = "tcp"
    from_port = 1
    to_port   = 65535
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol  = "udp"
    from_port = 1
    to_port   = 65535
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
