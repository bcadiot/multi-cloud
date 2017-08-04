output "gcp_network" {
  value = "${google_compute_network.nomad.name}"
}

output "gcp_subnetwork" {
  value = "${google_compute_subnetwork.default-nomad.name}"
}

output "aws_vpc" {
  value = "${aws_vpc.nomad.id}"
}

output "aws_subnet" {
  value = "${aws_subnet.nomad.*.id}"
}

output "aws_igw" {
  value = "${aws_internet_gateway.gw.id}"
}

output "gcp_bastion_ip" {
  value = [
      "${google_compute_instance.bastion.network_interface.0.access_config.0.assigned_nat_ip}",
      "${google_compute_instance.bastion.network_interface.0.address}"
  ]
}

output "aws_bastion_ip" {
  value = [
      "${aws_instance.bastion.public_ip}",
      "${aws_instance.bastion.private_ip}"
  ]
}
