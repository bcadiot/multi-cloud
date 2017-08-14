output "gcp_consul_ips" {
  value = ["${google_compute_instance.consul.*.network_interface.0.address}"]
}
