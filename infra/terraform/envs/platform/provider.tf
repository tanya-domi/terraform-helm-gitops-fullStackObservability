# 1. GCP Provider Configuration
provider "google" {
  project = var.project_id
  region  = var.region
}

# 2. Get GCP Client Config for OAuth Token
data "google_client_config" "default" {}

# 3. Fetch Cluster Metadata directly from GCP API
data "google_container_cluster" "primary" {
  name     = "boutique-gke-cluster"
  location = "us-central1-a" 
  project  = var.project_id
}

# 4. Kubernetes Provider
provider "kubernetes" {
  host                   = "https://${data.google_container_cluster.primary.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.primary.master_auth[0].cluster_ca_certificate)
}

# 5. Helm Provider 
provider "helm" {
  kubernetes = {
    host                   = "https://${data.google_container_cluster.primary.endpoint}"
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(data.google_container_cluster.primary.master_auth[0].cluster_ca_certificate)
  }
}