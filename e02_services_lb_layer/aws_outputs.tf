output "aws_consul_ips" {
  value = ["${aws_instance.consul.*.private_ip}"]
}

output "aws_traefik_ips" {
  value = [
      "${aws_instance.traefik.*.public_ip}",
      "${aws_instance.traefik.*.private_ip}"
    ]
}

output "aws_consul_client_sg" {
  value = "${aws_security_group.consul_clients.id}"
}

output "aws_traefik_sg" {
  value = "${aws_security_group.traefik.id}"
}
