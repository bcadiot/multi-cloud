output "gcp_nomad_servers_ips" {
  value = ["${google_compute_instance.nomad_servers.*.network_interface.0.address}"]
}

output "gcp_nomad_clients_ips" {
  value = ["${google_compute_instance.nomad_clients.*.network_interface.0.address}"]
}
