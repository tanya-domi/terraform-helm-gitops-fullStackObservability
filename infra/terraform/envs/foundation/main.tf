# # ==============================================================================
# # Dynamic Identity Formulation (Locals)
# # ==============================================================================
# locals {
#   build_ci_sa_email   = "${var.build_ci_sa_name}@${var.project_id}.iam.gserviceaccount.com"
#   promote_ci_sa_email = "${var.promote_ci_sa_name}@${var.project_id}.iam.gserviceaccount.com"
# }

# # ==============================================================================
# # Core Foundation Modules & Infrastructure
# # ==============================================================================

# # Call your decoupled baseline networking module
# module "network" {
#   source = "../../modules/network"

#   env                 = var.env
#   region              = var.region
#   vpc_name            = var.vpc_name
#   public_subnet_cidr  = var.public_subnet1_cidr
#   private_subnet_cidr = var.subnet_cidr
#   pods_cidr           = var.pods_cidr
#   services_cidr       = var.services_cidr
# }

# # Allocation block for Google Private Services Access (e.g. MemoryStore Redis)
# resource "google_compute_global_address" "redis_private_ip_range" {
#   name          = "${var.env}-redis-private-ip"
#   purpose       = "VPC_PEERING"
#   address_type  = "INTERNAL"
#   prefix_length = 16
#   network       = module.network.network_id
# }

# resource "google_project_service" "service_networking" {
#   service            = "servicenetworking.googleapis.com"
#   disable_on_destroy = false
# }

# resource "google_service_networking_connection" "private_vpc_connection" {
#   network                 = module.network.network_id
#   service                 = "servicenetworking.googleapis.com"
#   reserved_peering_ranges = [google_compute_global_address.redis_private_ip_range.name]
#   deletion_policy         = "ABANDON"

#   depends_on = [google_project_service.service_networking]
# }

# # Secure ingress rule restricted explicitly from GKE Pod allocations down to Private Service Peering range
# resource "google_compute_firewall" "allow_gke_to_redis" {
#   name    = "${var.env}-allow-gke-to-redis"
#   network = module.network.network_name

#   allow {
#     protocol = "tcp"
#     ports    = ["6379"]
#   }

#   source_ranges      = [var.pods_cidr]
#   destination_ranges = ["${google_compute_global_address.redis_private_ip_range.address}/${google_compute_global_address.redis_private_ip_range.prefix_length}"]
# }

# resource "google_project_service" "redis" {
#   service            = "redis.googleapis.com"
#   disable_on_destroy = false
# }

# # Enterprise High-Availability Managed Cache Layer
# resource "google_redis_instance" "cache" {
#   name           = "${var.env}-online-boutique-cache"
#   tier           = "STANDARD_HA"
#   memory_size_gb = 5
#   region         = var.region

#   authorized_network = module.network.network_id
#   connect_mode       = "PRIVATE_SERVICE_ACCESS"
#   redis_version      = "REDIS_7_0"

#   depends_on = [
#     google_project_service.redis,
#     google_service_networking_connection.private_vpc_connection
#   ]
# }

# # Core secrets management storage container
# resource "google_project_service" "secretmanager" {
#   service            = "secretmanager.googleapis.com"
#   disable_on_destroy = false
# }

# resource "google_secret_manager_secret" "redis_endpoint_secret" {
#   secret_id = "${var.env}-redis-endpoint"
#   replication {
#     auto {}
#   }
#   depends_on = [google_project_service.secretmanager]
# }

# resource "google_secret_manager_secret_version" "redis_endpoint_version" {
#   secret      = google_secret_manager_secret.redis_endpoint_secret.id
#   secret_data = "${google_redis_instance.cache.host}:${google_redis_instance.cache.port}"
# }




# ==============================================================================
# Dynamic Identity Formulation (Locals)
# ==============================================================================
locals {
  build_ci_sa_email   = "${var.build_ci_sa_name}@${var.project_id}.iam.gserviceaccount.com"
  promote_ci_sa_email = "${var.promote_ci_sa_name}@${var.project_id}.iam.gserviceaccount.com"
}

# ==============================================================================
# Required Foundational GCP APIs
# ==============================================================================
resource "google_project_service" "required_apis" {
  for_each = toset([
    "artifactregistry.googleapis.com",
    "iamcredentials.googleapis.com",
    "container.googleapis.com",
    "servicenetworking.googleapis.com",
    "cloudkms.googleapis.com"
  ])

  project            = var.project_id
  service            = each.key
  disable_on_destroy = false
}

# ==============================================================================
# Core Foundation Modules & Infrastructure Networking
# ==============================================================================
module "network" {
  source = "../../modules/network"

  env                 = var.env
  region              = var.region
  vpc_name            = var.vpc_name
  public_subnet_cidr  = var.public_subnet1_cidr
  private_subnet_cidr = var.subnet_cidr
  pods_cidr           = var.pods_cidr
  services_cidr       = var.services_cidr

  depends_on = [google_project_service.required_apis]
}

module "artifact_registry" {
  source = "../../modules/artifact_registry"

  project_id          = var.project_id
  env                 = var.env
  region              = var.region
  repositories        = ["app-images", "helm-charts"]
  github_pusher_email = "github-actions-pusher@${var.project_id}.iam.gserviceaccount.com"

  depends_on = [google_project_service.required_apis]
}

# ==============================================================================
# Base Service Accounts & Node IAM Roles
# ==============================================================================
resource "google_service_account" "gke_nodes" {
  account_id   = "${var.env}-gke-nodes-sa"
  display_name = "GKE Node Pool Worker Identity"
}

resource "google_project_iam_member" "node_roles" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/stackdriver.resourceMetadata.writer",
    "roles/autoscaling.metricsWriter",
    "roles/artifactregistry.reader"
  ])
  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

# ==============================================================================
# GKE Compute Cluster Layer
# ==============================================================================
module "gke" {
  source = "../../modules/gke"

  project_id                 = var.project_id
  env                        = var.env
  zone                       = var.zone
  cluster_name               = var.gke_cluster_name
  network_id                 = module.network.network_id
  subnet_id                  = module.network.private_subnet_id
  node_service_account_email = google_service_account.gke_nodes.email

  depends_on = [
    google_project_service.required_apis,
    google_project_iam_member.node_roles
  ]
}

# ==============================================================================
# Enterprise High-Availability Managed Cache Layer (Redis)
# ==============================================================================
resource "google_compute_global_address" "redis_private_ip_range" {
  name          = "${var.env}-redis-private-ip"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = module.network.network_id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = module.network.network_id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.redis_private_ip_range.name]
  deletion_policy         = "ABANDON"
}

resource "google_redis_instance" "cache" {
  name           = "${var.env}-online-boutique-cache"
  tier           = "STANDARD_HA"
  memory_size_gb = 5
  region         = var.region

  authorized_network = module.network.network_id
  connect_mode       = "PRIVATE_SERVICE_ACCESS"
  redis_version      = "REDIS_7_0"

  depends_on = [google_service_networking_connection.private_vpc_connection]
}

# ==============================================================================
# Enterprise Security Core (Cloud KMS Key Orchestration)
# ==============================================================================
module "kms" {
  source = "../../modules/kms"

  project_id      = var.project_id
  env             = var.env
  region          = var.region
  key_ring_name   = "online-boutique-ring"
  crypto_key_name = "app-secret-key"

  gke_service_account_email = google_service_account.gke_nodes.email

  depends_on = [google_project_service.required_apis]
}

# ==============================================================================
# Long-Term Observability Object Storage Backends (CMEK Encrypted)
# ==============================================================================
resource "google_storage_bucket" "tempo_store" {
  name                        = "${var.env}-tempo-backend-${var.project_id}"
  location                    = var.region
  force_destroy               = true
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true

  encryption {
    default_kms_key_name = module.kms.crypto_key_id
  }

  lifecycle_rule {
    condition {
      age = 7
    }
    action {
      type = "Delete"
    }
  }
}

resource "google_storage_bucket" "thanos_store" {
  name                        = "${var.env}-thanos-store-${var.project_id}"
  location                    = var.region
  force_destroy               = true
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true

  encryption {
    default_kms_key_name = module.kms.crypto_key_id
  }

  # Fixed single-argument block configuration line syntax rule
  lifecycle_rule {
    condition {
      age = 15
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }
}

# ==============================================================================
# Cross-System Workload Identities & IAM Handshakes
# ==============================================================================
resource "google_service_account" "observability_storage_sa" {
  account_id   = "${var.env}-observability-storage-sa"
  display_name = "Telemetry GCS backend identity access"
}

resource "google_storage_bucket_iam_member" "tempo_perms" {
  bucket = google_storage_bucket.tempo_store.name
  role   = "roles/storage.admin"
  member = "serviceAccount:${google_service_account.observability_storage_sa.email}"
}

resource "google_storage_bucket_iam_member" "thanos_perms" {
  bucket = google_storage_bucket.thanos_store.name
  role   = "roles/storage.admin"
  member = "serviceAccount:${google_service_account.observability_storage_sa.email}"
}

resource "google_service_account_iam_member" "thanos_tempo_workload" {
  service_account_id = google_service_account.observability_storage_sa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[monitoring/thanos-tempo-sa]"
}

# GitOps Engine Service Accounts & Identity Links
resource "google_service_account" "argocd_repo_server" {
  account_id   = "${var.env}-argocd-repo-sa"
  display_name = "ArgoCD Repo Server Identity"
}

resource "google_service_account" "argocd_image_updater" {
  account_id   = "${var.env}-argocd-updater-sa"
  display_name = "ArgoCD Image Updater Identity"
}

resource "google_project_iam_member" "argocd_artifact_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.argocd_repo_server.email}"
}

resource "google_project_iam_member" "updater_artifact_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.argocd_image_updater.email}"
}

resource "google_service_account_iam_member" "argocd_workload_identity" {
  service_account_id = google_service_account.argocd_repo_server.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[argocd/argocd-repo-server]"
}

resource "google_service_account_iam_member" "updater_workload_identity" {
  service_account_id = google_service_account.argocd_image_updater.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[argocd/argocd-image-updater]"
}

# Static External Route Allocation for Global HTTP Ingress Architecture
resource "google_compute_global_address" "boutique_ip" {
  name        = "${var.env}-online-boutique-ingress-ip"
  description = "Static External IP Address targeting Application Layer Ingress"
}

# ==============================================================================
# Automated Managed DNS Infrastructure
# ==============================================================================
module "dns_routing" {
  source = "../../modules/dns"

  project_id         = var.project_id
  zone_name          = "custom-domain"
  subdomain          = var.env
  target_ip_address  = google_compute_global_address.boutique_ip.address
}

# ==============================================================================
# ArgoCD Core GitOps Engine Deployment
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

  # Make sure the GKE cluster engine module is completely provisioned before running Helm
  depends_on = [module.gke]
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