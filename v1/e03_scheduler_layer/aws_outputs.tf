output "aws_nomad_servers_ips" {
  value = ["${aws_instance.nomad_servers.*.private_ip}"]
}

output "aws_nomad_clients_ips" {
  value = ["${aws_instance.nomad_clients.*.private_ip}"]
}

output "aws_nomad_client_sg" {
  value = "${aws_security_group.nomad_clients.id}"
}
