output "network_id" {
  value       = google_compute_network.main.id
  description = "The ID of the managed VPC network"
}

output "network_name" {
  value       = google_compute_network.main.name
  description = "The name of the managed VPC network"
}

output "private_subnet_id" {
  value       = google_compute_subnetwork.private.id
  description = "The ID of the private subnetwork"
}

output "pod_range_name" {
  value       = google_compute_subnetwork.private.secondary_ip_range[0].range_name
  description = "The secondary range name allocated for Pods"
}

output "service_range_name" {
  value       = google_compute_subnetwork.private.secondary_ip_range[1].range_name
  description = "The secondary range name allocated for Services"
}


