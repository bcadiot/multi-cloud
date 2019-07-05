# VPC specs

resource "google_compute_network" "main" {
  name                    = "main"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "subnet" {
  name          = "subnet"
  ip_cidr_range = var.gcp_cidr
  network       = google_compute_network.main.self_link
}

resource "google_compute_router" "main" {
  name    = "router-main"
  network = google_compute_network.main.self_link

  bgp {
    asn = var.bgp_gcp
  }
}

# VPN specs

resource "google_compute_vpn_gateway" "target_gateway" {
  name    = "vpn-aws"
  network = google_compute_network.main.self_link
}

resource "google_compute_address" "vpn_static_ip" {
  name = "vpn-static-ip"
}

resource "google_compute_forwarding_rule" "main_esp" {
  name        = "vpn-gw-1-esp"
  ip_protocol = "ESP"
  ip_address  = google_compute_address.vpn_static_ip.address
  target      = google_compute_vpn_gateway.target_gateway.self_link
}

resource "google_compute_forwarding_rule" "main_udp500" {
  name        = "vpn-gw-1-udp-500"
  ip_protocol = "UDP"
  port_range  = "500-500"
  ip_address  = google_compute_address.vpn_static_ip.address
  target      = google_compute_vpn_gateway.target_gateway.self_link
}

resource "google_compute_forwarding_rule" "main_udp4500" {
  name        = "vpn-gw-1-udp-4500"
  ip_protocol = "UDP"
  port_range  = "4500-4500"
  ip_address  = google_compute_address.vpn_static_ip.address
  target      = google_compute_vpn_gateway.target_gateway.self_link
}

resource "google_compute_vpn_tunnel" "main-1" {
  name               = "vpn-tunnel-1"
  target_vpn_gateway = google_compute_vpn_gateway.target_gateway.self_link
  shared_secret      = aws_vpn_connection.main.tunnel1_preshared_key
  peer_ip            = aws_vpn_connection.main.tunnel1_address
  router             = google_compute_router.main.name
  ike_version        = 2

  depends_on = [
    google_compute_forwarding_rule.main_esp,
    google_compute_forwarding_rule.main_udp500,
    google_compute_forwarding_rule.main_udp4500,
  ]
}

resource "google_compute_vpn_tunnel" "main-2" {
  name               = "vpn-tunnel-2"
  target_vpn_gateway = google_compute_vpn_gateway.target_gateway.self_link
  shared_secret      = aws_vpn_connection.main.tunnel2_preshared_key
  peer_ip            = aws_vpn_connection.main.tunnel2_address
  router             = google_compute_router.main.name
  ike_version        = 2

  depends_on = [
    google_compute_forwarding_rule.main_esp,
    google_compute_forwarding_rule.main_udp500,
    google_compute_forwarding_rule.main_udp4500,
  ]
}

resource "google_compute_router_interface" "main-1" {
  name       = "interface-1"
  router     = google_compute_router.main.name
  ip_range   = "${aws_vpn_connection.main.tunnel1_cgw_inside_address}/30"
  vpn_tunnel = google_compute_vpn_tunnel.main-1.name
}

resource "google_compute_router_interface" "main-2" {
  name       = "interface-2"
  router     = google_compute_router.main.name
  ip_range   = "${aws_vpn_connection.main.tunnel2_cgw_inside_address}/30"
  vpn_tunnel = google_compute_vpn_tunnel.main-2.name
}

resource "google_compute_router_peer" "main-1" {
  name                      = "peer-1"
  router                    = google_compute_router.main.name
  peer_ip_address           = aws_vpn_connection.main.tunnel1_vgw_inside_address
  peer_asn                  = aws_vpn_connection.main.tunnel1_bgp_asn
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.main-1.name
}

resource "google_compute_router_peer" "main-2" {
  name                      = "peer-2"
  router                    = google_compute_router.main.name
  peer_ip_address           = aws_vpn_connection.main.tunnel2_vgw_inside_address
  peer_asn                  = aws_vpn_connection.main.tunnel2_bgp_asn
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.main-2.name
}

