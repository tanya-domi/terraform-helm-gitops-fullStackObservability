resource "google_service_account" "prometheus" {
  project      = var.project_id
  account_id   = "${var.env}-prometheus-gsa"
  display_name = "Prometheus telemetry system execution context"
}

resource "google_project_iam_member" "prometheus_capabilities" {
  for_each = toset([
    "roles/pubsub.subscriber",
    "roles/secretmanager.secretAccessor"
  ])
  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.prometheus.email}"
}

# Granular, bucket-scoped access instead of broad project-level permissions
resource "google_storage_bucket_iam_member" "prometheus_storage" {
  bucket = google_storage_bucket.observability_buckets["thanos"].name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.prometheus.email}"
}

resource "google_service_account_iam_member" "prometheus_workload_identity" {
  service_account_id = google_service_account.prometheus.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[monitoring/prometheus]"
}

resource "kubernetes_service_account_v1" "prometheus" {
  metadata {
    name      = "prometheus"
    namespace = kubernetes_namespace_v1.monitoring.metadata[0].name
    annotations = {
      "iam.gke.io/gcp-service-account" = google_service_account.prometheus.email
    }
  }
}