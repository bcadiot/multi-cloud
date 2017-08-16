output "gcp_consul_ips" {
  value = ["${google_compute_instance.consul.*.network_interface.0.address}"]
}

output "gcp_traefik_ips" {
  value = [
      "${google_compute_instance.traefik.*.network_interface.0.access_config.0.assigned_nat_ip}",
      "${google_compute_instance.traefik.*.network_interface.0.address}"
    ]
}
