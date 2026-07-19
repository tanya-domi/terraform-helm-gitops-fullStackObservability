resource "google_service_account" "grafana" {
  project      = var.project_id
  account_id   = "${var.env}-grafana-gsa"
  display_name = "Grafana dashboard data extraction layer"
}

resource "google_project_iam_member" "grafana_monitoring_viewer" {
  project = var.project_id
  role    = "roles/monitoring.viewer"
  member  = "serviceAccount:${google_service_account.grafana.email}"
}

resource "google_storage_bucket_iam_member" "grafana_storage" {
  for_each = toset(["thanos", "tempo"])
  bucket   = google_storage_bucket.observability_buckets[each.key].name
  role     = "roles/storage.objectViewer"
  member   = "serviceAccount:${google_service_account.grafana.email}"
}

resource "google_service_account_iam_member" "grafana_workload_identity" {
  service_account_id = google_service_account.grafana.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[monitoring/grafana]"
}

resource "kubernetes_service_account_v1" "grafana" {
  metadata {
    name      = "grafana"
    namespace = kubernetes_namespace_v1.monitoring.metadata[0].name
    annotations = {
      "iam.gke.io/gcp-service-account" = google_service_account.grafana.email
    }
  }
}