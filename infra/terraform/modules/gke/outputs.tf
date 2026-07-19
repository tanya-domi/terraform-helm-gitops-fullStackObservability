# output "cluster_name" {
#   value = google_container_cluster.primary.name
# }

# output "cluster_endpoint" {
#   value = google_container_cluster.primary.endpoint
# }

# output "cluster_ca_certificate" {
#   value = google_container_cluster.primary.master_auth[0].cluster_ca_certificate
# }



output "cluster_name" {
  description = "The verified name of the running GKE Kubernetes cluster."
  value       = google_container_cluster.primary.name
}

output "cluster_id" {
  description = "The fully qualified resource URI identifier of the GKE cluster."
  value       = google_container_cluster.primary.id
}

output "cluster_endpoint" {
  description = "The network endpoint API address for Kubernetes cluster control."
  value       = google_container_cluster.primary.endpoint
}

output "service_account" {
  description = "Standard service account fallback for workload IAM policies."
  value       = "default"
}