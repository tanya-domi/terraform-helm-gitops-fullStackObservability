resource "google_service_account" "tempo_thanos" {
  project      = var.project_id
  account_id   = "${var.env}-tempo-thanos-gsa"
  display_name = "Shared tracking storage ingestion gateway"
}

resource "google_storage_bucket_iam_member" "tempo_write" {
  bucket = google_storage_bucket.observability_buckets["tempo"].name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.tempo_thanos.email}"
}

resource "google_storage_bucket_iam_member" "thanos_write" {
  bucket = google_storage_bucket.observability_buckets["thanos"].name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.tempo_thanos.email}"
}

resource "google_service_account_iam_member" "tempo_thanos_workload_identity" {
  service_account_id = google_service_account.tempo_thanos.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[monitoring/thanos-tempo-sa]"
}

resource "kubernetes_service_account_v1" "thanos_tempo" {
  metadata {
    name      = "thanos-tempo-sa"
    namespace = kubernetes_namespace_v1.monitoring.metadata[0].name
    annotations = {
      "iam.gke.io/gcp-service-account" = google_service_account.tempo_thanos.email
    }
  }
}