output "aws_vpc" {
  value = aws_vpc.main.id
}

output "aws_subnets" {
  value = aws_subnet.main.*.id
}

output "gcp_vpc" {
  value = google_compute_network.main.self_link
}