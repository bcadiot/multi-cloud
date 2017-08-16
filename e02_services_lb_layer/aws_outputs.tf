output "aws_servers_ips" {
  value = ["${aws_instance.consul.*.private_ip}"]
}
