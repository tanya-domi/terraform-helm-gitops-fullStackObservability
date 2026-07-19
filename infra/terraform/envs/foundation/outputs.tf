output "vpc_network_name" {
  value = module.network.network_name
}

output "gke_subnetwork_name" {
  value = module.network.subnetwork_name
}

output "redis_connection_host" {
  value = google_redis_instance.cache.host
}

output "cluster_name" {
  value = module.gke.cluster_name
}

output "cluster_endpoint" {
  value = module.gke.cluster_endpoint
}

output "boutique_gateway_ip_address" {
  description = "Static External IP reserved for Ingress traffic routing"
  value       = google_compute_global_address.gateway.address
}

output "tempo_bucket_name" {
  description = "GCS Object Storage bucket name allocated for Tempo Traces"
  value       = google_storage_bucket.tempo_store.name
}

output "thanos_bucket_name" {
  description = "GCS Object Storage bucket name allocated for Thanos Metrics"
  value       = google_storage_bucket.thanos_store.name
}

output "observability_storage_sa_email" {
  description = "Service Account email used by Telemetry storage layers"
  value       = google_service_account.observability_storage_sa.email
}

output "artifact_repository_urls" {
  value       = module.custom_artifact_registry.repository_urls
  description = "OCI container registry targets for building images and pushing Helm charts."
}

# Automated Workload Identities (CI/CD Pipelines)
# ==============================================================================

output "build_ci_sa_email" {
  description = "Fully qualified email address of the build CI service account executor."
  value       = var.build_ci_sa_name
}

output "promote_ci_sa_email" {
  description = "Fully qualified email address of the promotional deployment CI service account executor."
  value       = var.promote_ci_sa_name
}