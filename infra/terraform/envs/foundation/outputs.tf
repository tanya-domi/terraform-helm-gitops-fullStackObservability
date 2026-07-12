output "vpc_network_id" {
  value = module.network.network_id
}

output "gke_private_subnet_id" {
  value = module.network.private_subnet_id
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

output "boutique_dev_ip_address" {
  description = "Static External IP reserved for Ingress traffic routing"
  value       = google_compute_global_address.boutique_ip.address
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