resource "google_service_account" "eso" {
  project      = var.project_id
  account_id   = "${var.env}-eso-gsa"
  display_name = "External Secrets Operator platform token orchestrator"
}

resource "google_project_iam_member" "eso_secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.eso.email}"
}

resource "google_service_account_iam_member" "eso_workload_identity" {
  service_account_id = google_service_account.eso.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[external-secrets/external-secrets-sa]"
}

resource "kubernetes_service_account_v1" "eso" {
  metadata {
    name      = "external-secrets-sa"
    namespace = kubernetes_namespace_v1.external_secrets.metadata[0].name
    annotations = {
      "iam.gke.io/gcp-service-account" = google_service_account.eso.email
    }
  }
}