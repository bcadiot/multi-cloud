# Routing specs

resource "google_compute_router" "main" {
  name    = "router-main"
  network = var.gcp_vpc

  bgp {
    asn = var.gcp_bgp
    # advertise_mode    = "CUSTOM"
    # advertised_groups = ["ALL_SUBNETS"]

    # advertised_ip_ranges {
    #   range = "35.199.192.0/19"
    #   description = "Cloud DNS Managed Private Zone Forwarding"
    # }
  }
}

# VPN specs

resource "google_compute_ha_vpn_gateway" "target_gateway" {
  provider = "google-beta"
  name     = "vpn-aws"
  network  = var.gcp_vpc
}

resource "google_compute_external_vpn_gateway" "aws_gateway" {
  provider        = "google-beta"
  name            = "aws-gateway"
  redundancy_type = "FOUR_IPS_REDUNDANCY"
  description     = "VPN gateway on AWS side"

  interface {
    id         = 0
    ip_address = aws_vpn_connection.cx_1.tunnel1_address
  }

  interface {
    id         = 1
    ip_address = aws_vpn_connection.cx_1.tunnel2_address
  }

  interface {
    id         = 2
    ip_address = aws_vpn_connection.cx_2.tunnel1_address
  }

  interface {
    id         = 3
    ip_address = aws_vpn_connection.cx_2.tunnel2_address
  }
}

resource "google_compute_vpn_tunnel" "main-1" {
  provider                        = "google-beta"
  name                            = "vpn-tunnel-1"
  vpn_gateway                     = google_compute_ha_vpn_gateway.target_gateway.self_link
  shared_secret                   = aws_vpn_connection.cx_1.tunnel1_preshared_key
  peer_external_gateway           = google_compute_external_vpn_gateway.aws_gateway.self_link
  peer_external_gateway_interface = 0
  router                          = google_compute_router.main.name
  ike_version                     = 2
  vpn_gateway_interface           = 0
}

resource "google_compute_vpn_tunnel" "main-2" {
  provider                        = "google-beta"
  name                            = "vpn-tunnel-2"
  vpn_gateway                     = google_compute_ha_vpn_gateway.target_gateway.self_link
  shared_secret                   = aws_vpn_connection.cx_1.tunnel2_preshared_key
  peer_external_gateway           = google_compute_external_vpn_gateway.aws_gateway.self_link
  peer_external_gateway_interface = 1
  router                          = google_compute_router.main.name
  ike_version                     = 2
  vpn_gateway_interface           = 0
}

resource "google_compute_vpn_tunnel" "main-3" {
  provider                        = "google-beta"
  name                            = "vpn-tunnel-3"
  vpn_gateway                     = google_compute_ha_vpn_gateway.target_gateway.self_link
  shared_secret                   = aws_vpn_connection.cx_2.tunnel1_preshared_key
  peer_external_gateway           = google_compute_external_vpn_gateway.aws_gateway.self_link
  peer_external_gateway_interface = 2
  router                          = google_compute_router.main.name
  ike_version                     = 2
  vpn_gateway_interface           = 1
}

resource "google_compute_vpn_tunnel" "main-4" {
  provider                        = "google-beta"
  name                            = "vpn-tunnel-4"
  vpn_gateway                     = google_compute_ha_vpn_gateway.target_gateway.self_link
  shared_secret                   = aws_vpn_connection.cx_2.tunnel2_preshared_key
  peer_external_gateway           = google_compute_external_vpn_gateway.aws_gateway.self_link
  peer_external_gateway_interface = 3
  router                          = google_compute_router.main.name
  ike_version                     = 2
  vpn_gateway_interface           = 1
}

resource "google_compute_router_interface" "main-1" {
  name       = "interface-1"
  router     = google_compute_router.main.name
  ip_range   = "${aws_vpn_connection.cx_1.tunnel1_cgw_inside_address}/30"
  vpn_tunnel = google_compute_vpn_tunnel.main-1.name
}

resource "google_compute_router_interface" "main-2" {
  name       = "interface-2"
  router     = google_compute_router.main.name
  ip_range   = "${aws_vpn_connection.cx_1.tunnel2_cgw_inside_address}/30"
  vpn_tunnel = google_compute_vpn_tunnel.main-2.name
}

resource "google_compute_router_interface" "main-3" {
  name       = "interface-3"
  router     = google_compute_router.main.name
  ip_range   = "${aws_vpn_connection.cx_2.tunnel1_cgw_inside_address}/30"
  vpn_tunnel = google_compute_vpn_tunnel.main-3.name
}

resource "google_compute_router_interface" "main-4" {
  name       = "interface-4"
  router     = google_compute_router.main.name
  ip_range   = "${aws_vpn_connection.cx_2.tunnel2_cgw_inside_address}/30"
  vpn_tunnel = google_compute_vpn_tunnel.main-4.name
}

resource "google_compute_router_peer" "main-1" {
  name                      = "peer-1"
  router                    = google_compute_router.main.name
  peer_ip_address           = aws_vpn_connection.cx_1.tunnel1_vgw_inside_address
  peer_asn                  = aws_vpn_connection.cx_1.tunnel1_bgp_asn
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.main-1.name
}

resource "google_compute_router_peer" "main-2" {
  name                      = "peer-2"
  router                    = google_compute_router.main.name
  peer_ip_address           = aws_vpn_connection.cx_1.tunnel2_vgw_inside_address
  peer_asn                  = aws_vpn_connection.cx_1.tunnel2_bgp_asn
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.main-2.name
}

resource "google_compute_router_peer" "main-3" {
  name                      = "peer-3"
  router                    = google_compute_router.main.name
  peer_ip_address           = aws_vpn_connection.cx_2.tunnel1_vgw_inside_address
  peer_asn                  = aws_vpn_connection.cx_2.tunnel1_bgp_asn
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.main-3.name
}

resource "google_compute_router_peer" "main-4" {
  name                      = "peer-4"
  router                    = google_compute_router.main.name
  peer_ip_address           = aws_vpn_connection.cx_2.tunnel2_vgw_inside_address
  peer_asn                  = aws_vpn_connection.cx_2.tunnel2_bgp_asn
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.main-4.name
}
