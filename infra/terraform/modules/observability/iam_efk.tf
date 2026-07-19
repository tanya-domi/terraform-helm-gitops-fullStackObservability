resource "google_service_account" "efk" {
  project      = var.project_id
  account_id   = "${var.env}-elasticsearch-gsa"
  display_name = "Elasticsearch long-term state logging context"
}

# ANTI-PATTERN CORRECTION: Downgraded storage.admin to storage.objectAdmin
resource "google_storage_bucket_iam_member" "efk_storage" {
  bucket = google_storage_bucket.observability_buckets["elasticsearch-archive"].name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.efk.email}"
}

resource "google_service_account_iam_member" "efk_workload_identity" {
  service_account_id = google_service_account.efk.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[efk/elasticsearch-ksa]"
}

resource "kubernetes_service_account_v1" "elasticsearch" {
  metadata {
    name      = "elasticsearch-ksa"
    namespace = kubernetes_namespace_v1.efk.metadata[0].name
    annotations = {
      "iam.gke.io/gcp-service-account" = google_service_account.efk.email
    }
  }
}