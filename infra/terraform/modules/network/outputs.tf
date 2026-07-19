# output "network_id" {
#   value       = google_compute_network.main.id
#   description = "The ID of the managed VPC network"
# }

# output "network_name" {
#   value       = google_compute_network.main.name
#   description = "The name of the managed VPC network"
# }

# output "private_subnet_id" {
#   value       = google_compute_subnetwork.private.id
#   description = "The ID of the private subnetwork"
# }

# output "pod_range_name" {
#   value       = google_compute_subnetwork.private.secondary_ip_range[0].range_name
#   description = "The secondary range name allocated for Pods"
# }

# output "service_range_name" {
#   value       = google_compute_subnetwork.private.secondary_ip_range[1].range_name
#   description = "The secondary range name allocated for Services"
# }


output "network_name" {
  value       = google_compute_network.vpc.name
  description = "The exact execution name string of the managed VPC network."
}

output "subnetwork_name" {
  value       = google_compute_subnetwork.gke.name
  description = "The name string mapping directly to the target subnetwork instance."
}

output "pods_range_name" {
  value       = local.pods_range
  description = "The secondary range key matching GKE pod allocations."
}

output "services_range_name" {
  value       = local.services_range
  description = "The secondary range key matching GKE service allocations."
}