resource "aws_security_group" "minio" {
  vpc_id      = "${data.terraform_remote_state.network.aws_vpc}"
  name        = "minio_sg"

  # Minio communication
  ingress {
    protocol  = "tcp"
    from_port = 9000
    to_port   = 9000
    cidr_blocks = ["172.27.3.0/24", "172.30.3.0/24"]
  }
}
