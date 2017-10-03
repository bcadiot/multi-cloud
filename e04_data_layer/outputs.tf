output "gcp_datanode_ips" {
  value = ["${google_compute_instance.datanode.*.network_interface.0.address}"]
}

output "aws_datanode_ips" {
  value = ["${aws_instance.datanode.*.private_ip}"]
}
