# Security Groups Configuration

resource "aws_security_group" "consul_servers" {
  vpc_id      = "${data.terraform_remote_state.network.aws_vpc}"
  name        = "consul_servers_sg"

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

  # Consul RPC + Serf
  ingress {
    protocol  = "tcp"
    from_port = 8300
    to_port   = 8302
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Consul RPC + Serf (UDP)
  ingress {
    protocol  = "udp"
    from_port = 8301
    to_port   = 8302
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Consul HTTP API
  ingress {
    protocol  = "tcp"
    from_port = 8500
    to_port   = 8500
    cidr_blocks = ["0.0.0.0/0"]
  }

  # DNS Interface TCP
  ingress {
    protocol  = "tcp"
    from_port = 53
    to_port   = 53
    cidr_blocks = ["0.0.0.0/0"]
  }

  # DNS Interface UDP
  ingress {
    protocol  = "udp"
    from_port = 53
    to_port   = 53
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "consul_clients" {
  vpc_id      = "${data.terraform_remote_state.network.aws_vpc}"
  name        = "consul_clients_sg"

  # ICMP
  ingress {
    protocol  = "icmp"
    from_port = 8
    to_port   = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Consul RPC + Serf
  ingress {
    protocol  = "tcp"
    from_port = 8300
    to_port   = 8301
    security_groups = ["${aws_security_group.consul_servers.id}"]
    self = true
  }

  # Consul RPC + Serf (UDP)
  ingress {
    protocol  = "udp"
    from_port = 8301
    to_port   = 8301
    security_groups = ["${aws_security_group.consul_servers.id}"]
    self = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "traefik" {
  vpc_id      = "${data.terraform_remote_state.network.aws_vpc}"
  name        = "traefik_sg"

  # ICMP
  ingress {
    protocol  = "icmp"
    from_port = 8
    to_port   = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP
  ingress {
    protocol  = "tcp"
    from_port = 80
    to_port   = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS
  ingress {
    protocol  = "tcp"
    from_port = 443
    to_port   = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "traefik_adm" {
  vpc_id      = "${data.terraform_remote_state.network.aws_vpc}"
  name        = "traefik_adm_sg"

  # ICMP
  ingress {
    protocol  = "icmp"
    from_port = 8
    to_port   = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP ADM
  ingress {
    protocol  = "tcp"
    from_port = 8080
    to_port   = 8080
    security_groups = ["${data.terraform_remote_state.network.aws_bastion_sg}"]
  }

  # SSH Bastion
  ingress {
    protocol  = "tcp"
    from_port = 22
    to_port   = 22
    security_groups = ["${data.terraform_remote_state.network.aws_bastion_sg}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

// # IAM Configuration

// resource "aws_iam_instance_profile" "consul" {
//
//   name = "consul-instance-profile"
//   role = "${aws_iam_role.consul.name}"
// }
//
// resource "aws_iam_role" "consul" {
//   name = "consul-role"
//   path = "/"
//
//   assume_role_policy = <<EOF
// {
//     "Version": "2012-10-17",
//     "Statement": [
//         {
//             "Action": "sts:AssumeRole",
//             "Principal": {
//                "Service": "ec2.amazonaws.com"
//             },
//             "Effect": "Allow",
//             "Sid": ""
//         }
//     ]
// }
// EOF
// }
//
//
// resource "aws_iam_role_policy" "consul" {
//   name_prefix = "consul"
//
//   role = "${aws_iam_role.consul.id}"
//
//   policy = <<EOF
// {
//   "Version": "2012-10-17",
//   "Statement": [
//     {
//       "Action": [
//         "ec2:DescribeInstances"
//       ],
//       "Effect": "Allow",
//       "Resource": "*"
//     }
//   ]
// }
// EOF
// }
