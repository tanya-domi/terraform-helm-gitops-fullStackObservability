
provider "google" {
  project               = var.project_id
  region                = var.region
  zone                  = var.zone
  user_project_override = true
  billing_project       = var.project_id
}

data "google_client_config" "default" {}

# provider "kubernetes" {
#   host                   = "https://${module.gke.cluster_endpoint}"
#   token                  = data.google_client_config.default.access_token
#   cluster_ca_certificate = base64decode(module.gke.cluster_ca_certificate)
# }

# provider "helm" {
#   kubernetes {
#     host                   = "https://${module.gke.cluster_endpoint}"
#     token                  = data.google_client_config.default.access_token
#     cluster_ca_certificate = base64decode(module.gke.cluster_ca_certificate)
#   }
# }


