# ==============================================================================
# 1. GCP IAM & WORKLOAD IDENTITY SETUP
# ==============================================================================

# Service Account for ArgoCD Repo Server
resource "google_service_account" "argocd_repo_server" {
  project      = var.project_id
  account_id   = "argocd-repo-server-sa"
  display_name = "ArgoCD Repo Server Service Account"
}

# Service Account for ArgoCD Image Updater
resource "google_service_account" "argocd_image_updater" {
  project      = var.project_id
  account_id   = "argocd-image-updater-sa"
  display_name = "ArgoCD Image Updater Service Account"
}

# Grant Artifact Registry Reader to Repo Server
resource "google_project_iam_member" "argocd_artifact_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.argocd_repo_server.email}"
}

# Grant Artifact Registry Reader to Image Updater
resource "google_project_iam_member" "updater_artifact_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.argocd_image_updater.email}"
}

# Workload Identity Handshake for ArgoCD Repo Server
resource "google_service_account_iam_member" "argocd_workload_identity" {
  service_account_id = google_service_account.argocd_repo_server.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[argocd/argocd-repo-server]"
}

# Workload Identity Handshake for ArgoCD Image Updater
resource "google_service_account_iam_member" "updater_workload_identity" {
  service_account_id = google_service_account.argocd_image_updater.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[argocd/argocd-image-updater]"
}

# ==============================================================================
# 2. HELM RELEASE: ARGOCD
# ==============================================================================

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = "8.5.8"

  values = [
    templatefile("${path.module}/values/argocd.yaml", {
      project_id = var.project_id
    })
  ]

  depends_on = [
    google_service_account_iam_member.argocd_workload_identity
  ]
}

# ==============================================================================
# 3. KUBERNETES CONFIGMAP: GCP AUTH SCRIPT
# ==============================================================================

resource "kubernetes_config_map_v1" "auth_cm" {
  metadata {
    name      = "auth-cm"
    namespace = "argocd"
  }

  data = {
    "gcp-auth.sh" = <<-EOF
      #!/bin/sh
      ACCESS_TOKEN=$(wget --header 'Metadata-Flavor: Google' http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token -q -O - | grep -Eo '"access_token":.*?[^\\]",' | cut -d '"' -f 4)
      echo "oauth2accesstoken:$ACCESS_TOKEN"
    EOF
  }

  depends_on = [helm_release.argocd]
}

# ==============================================================================
# 4. HELM RELEASE: ARGOCD IMAGE UPDATER
# ==============================================================================

resource "helm_release" "argocd_image_updater" {
  name             = "argocd-image-updater"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argocd-image-updater"
  namespace        = "argocd"
  create_namespace = true
  version          = "0.12.3"

  values = [
    templatefile("${path.module}/values/image-updater.yaml", {
      project_id = var.project_id
    })
  ]

  depends_on = [
    helm_release.argocd,
    kubernetes_config_map_v1.auth_cm,
    google_service_account_iam_member.updater_workload_identity
  ]
}