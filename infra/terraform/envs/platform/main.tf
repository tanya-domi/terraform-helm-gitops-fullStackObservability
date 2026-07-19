data "terraform_remote_state" "foundation" {
  backend = "gcs" # Or local, depending on your backend config
  config = {
    bucket = "your-terraform-state-bucket"
    prefix = "foundation/state"
  }
}

provider "google" { region = var.region }

provider "kubernetes" {
  host                   = data.terraform_remote_state.foundation.outputs.cluster_endpoint
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(data.terraform_remote_state.foundation.outputs.cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = data.terraform_remote_state.foundation.outputs.cluster_endpoint
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(data.terraform_remote_state.foundation.outputs.cluster_ca_certificate)
  }
}

data "google_client_config" "default" {}


# ==============================================================================
# ArgoCD Core GitOps Engine Bootstrap Lifecycle
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

#   depends_on = [module.gke]
  depends_on = [data.terraform_remote_state.foundation]
}

resource "helm_release" "argocd_image_updater" {
  name             = "argocd-image-updater"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argocd-image-updater"
  namespace        = "argocd"
  create_namespace = true
  version          = "0.12.3"

  values = [file("${path.module}/values/image-updater.yaml")]

  depends_on = [helm_release.argocd]
}

resource "kubernetes_config_map_v1" "auth_cm" {
  metadata {
    name      = "auth-cm"
    namespace = "argocd"
  }

  data = {
    "gcp-auth.sh" = <<EOF
#!/bin/sh
ACCESS_TOKEN=$(wget --header 'Metadata-Flavor: Google' http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token -q -O - | grep -Eo '"access_token":.*?[^\\]",' | cut -d '"' -f 4)
echo "oauth2accesstoken:$ACCESS_TOKEN"
EOF
  }

  depends_on = [helm_release.argocd]
}