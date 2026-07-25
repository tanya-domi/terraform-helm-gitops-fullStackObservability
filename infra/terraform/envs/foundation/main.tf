# # ==============================================================================
# # Dynamic Identity Formulation & Standardized Labels
# # ==============================================================================
# locals {
#   name_prefix = "boutique"
#   labels = {
#     platform = "microservices-google"
#     managed  = "terraform"
#     env      = var.env
#   }
# }

# data "google_project" "current" {
#   project_id = var.project_id
# }

# # ==============================================================================
# # Required Foundational GCP APIs
# # ==============================================================================
# resource "google_project_service" "required_apis" {
#   for_each = toset([
#     "artifactregistry.googleapis.com",
#     "iamcredentials.googleapis.com",
#     "container.googleapis.com",
#     "servicenetworking.googleapis.com",
#     "cloudkms.googleapis.com",
#     "certificatemanager.googleapis.com",
#     "binaryauthorization.googleapis.com"
#   ])

#   project            = var.project_id
#   service            = each.key
#   disable_on_destroy = false
# }

# # ==============================================================================
# # Core Foundation Modules & Infrastructure Networking
# # ==============================================================================
# module "network" {
#   source = "../../modules/network"

#   project_id   = var.project_id
#   region       = var.region
#   network_name = "${local.name_prefix}-vpc"
#   subnet_name  = "${local.name_prefix}-gke"

#   depends_on = [google_project_service.required_apis]
# }

# # ==============================================================================
# # Enterprise Security Core (Cloud KMS Key Orchestration)
# # ==============================================================================
# module "kms" {
#   source = "../../modules/kms"

#   project_id = var.project_id
#   region     = var.region
#   key_ring   = "${local.name_prefix}-gke"
#   env        = var.env
#   crypto_key = "etcd-secrets"

#   depends_on = [google_project_service.required_apis]
# }

# # GKE Control Plane service identity mapping for etcd Database Encryption
# resource "google_kms_crypto_key_iam_member" "gke_etcd_encryption" {
#   crypto_key_id = module.kms.crypto_key_id
#   role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
#   member        = "serviceAccount:service-${data.google_project.current.number}@container-engine-robot.iam.gserviceaccount.com"
# }

# # ==============================================================================
# # GKE Compute Cluster Layer with Binary Authorization
# # ==============================================================================
# module "gke" {
#   source = "../../modules/gke"

#   project_id                 = var.project_id
#   env                        = var.env
#   region                     = var.region
#   cluster_name               = var.cluster_name
#   network                    = module.network.network_name
#   subnetwork                 = module.network.subnetwork_name
#   pods_range_name            = module.network.pods_range_name
#   services_range_name        = module.network.services_range_name
#   master_authorized_networks = var.master_authorized_networks
#   kms_key_id                 = module.kms.crypto_key_id

#   depends_on = [
#     google_project_service.required_apis,
#     google_kms_crypto_key_iam_member.gke_etcd_encryption
#   ]
# }

# resource "google_project_iam_member" "gke_nodes_artifact_registry_reader" {
#   project = "project-1cdbea51-6334-4e02-967"
#   role    = "roles/artifactregistry.reader"
#   member  = "serviceAccount:${google_service_account.gke_nodes.email}"
# }

# # Explicitly defining monitoring/logging permissions natively required by GKE Node Pools
# resource "google_project_iam_member" "node_telemetry_roles" {
#   for_each = toset([
#     "roles/logging.logWriter",
#     "roles/stackdriver.resourceMetadata.writer",
#     "roles/monitoring.metricWriter",
#     "roles/monitoring.viewer"
#   ])

#   project = "project-1cdbea51-6334-4e02-967"
#   role    = each.key
#   member  = "serviceAccount:${google_service_account.gke_nodes.email}"
# }

# # ==============================================================================
# # Supply Chain Security & Attestation Core
# # ==============================================================================
# module "binary_auth" {
#   source = "../../modules/binary_auth"

#   project_id = var.project_id
#   depends_on = [google_project_service.required_apis]
# }

# resource "google_binary_authorization_attestor_iam_member" "build_ci_attestor" {
#   project  = var.project_id
#   attestor = "boutique-cosign"
#   role     = "roles/binaryauthorization.attestorsViewer"
#   member   = "serviceAccount:${google_service_account.build_ci.email}"
# }

# # ==============================================================================
# # Managed Artifact Architecture & CI/CD Promotional Entitlements
# # ==============================================================================
# module "custom_artifact_registry" {
#   source = "../../modules/artifact_registry"

#   project_id        = var.project_id
#   region            = var.region
#   environment       = var.env
#   docker_registries = var.docker_registries
# }

# # Lifecycle RBAC assignments using the dynamically generated module names
# resource "google_artifact_registry_repository_iam_member" "build_ci_writer_dev" {
#   project    = var.project_id
#   location   = var.region
#   repository = "${var.env}-app-images"
#   role       = "roles/artifactregistry.writer"
#   member     = "serviceAccount:${google_service_account.build_ci.email}" #"serviceAccount:${var.build_ci_sa_name}"
#   depends_on = [module.custom_artifact_registry]
# }

# resource "google_artifact_registry_repository_iam_member" "promote_ci_reader_dev" {
#   project    = var.project_id
#   location   = var.region
#   repository = "${var.env}-${var.docker_registries[0]}"
#   role       = "roles/artifactregistry.reader"
#   member     = "serviceAccount:${google_service_account.promote_ci.email}"
# }

# resource "google_artifact_registry_repository_iam_member" "promote_ci_writer_stage" {
#   project    = var.project_id
#   location   = var.region
#   repository = "${var.env}-${var.docker_registries[0]}"
#   role       = "roles/artifactregistry.writer"
#   member     = "serviceAccount:${google_service_account.promote_ci.email}"
# }

# # ==============================================================================
# # SERVICE ACCOUNTS
# # ==============================================================================
# resource "google_service_account" "gke_nodes" {
#   account_id   = var.sa-gke-nodes
#   display_name = "Dedicated GKE Node System Account"
#   project      = var.project_id
# }

# resource "google_service_account" "build_ci" {
#   account_id   = var.build_ci_sa_name
#   display_name = "GitHub Actions CI Build Agent"
#   project      = var.project_id
# }

# resource "google_service_account" "promote_ci" {
#   account_id   = var.promote_ci_sa_name
#   display_name = "GitHub Actions CI Release Promotion Agent"
#   project      = var.project_id
# }
# # ==============================================================================
# # Managed Cloud Memorystore Redis
# # ==============================================================================
# resource "google_compute_global_address" "redis_private_ip_range" {
#   name          = "${local.name_prefix}-redis-private-ip"
#   purpose       = "VPC_PEERING"
#   address_type  = "INTERNAL"
#   prefix_length = 16
#   network       = module.network.network_name
# }

# resource "google_service_networking_connection" "private_vpc_connection" {
#   network                 = module.network.network_name
#   service                 = "servicenetworking.googleapis.com"
#   reserved_peering_ranges = [google_compute_global_address.redis_private_ip_range.name]
#   deletion_policy         = "ABANDON"
# }

# resource "google_redis_instance" "cache" {
#   name           = "${var.env}-online-boutique-cache"
#   tier           = "STANDARD_HA"
#   memory_size_gb = 5
#   region         = var.region

#   authorized_network = module.network.network_name
#   connect_mode       = "PRIVATE_SERVICE_ACCESS"
#   redis_version      = "REDIS_7_0"

#   labels = local.labels

#   depends_on = [google_service_networking_connection.private_vpc_connection]
# }
# # ==============================================================================
# # GCP Secret Manager & External Secrets Operator Integration
# # ==============================================================================

# # Enable Secret Manager API
# resource "google_project_service" "secretmanager" {
#   project            = var.project_id
#   service            = "secretmanager.googleapis.com"
#   disable_on_destroy = false
# }

# # Secret Container for Memorystore Redis Connection String
# resource "google_secret_manager_secret" "redis_endpoint" {
#   project   = var.project_id
#   secret_id = "redis-endpoint-${var.env}"

#   replication {
#     auto {}
#   }

#   labels = local.labels

#   depends_on = [google_project_service.secretmanager]
# }

# # Create Secret Version sourcing from the Redis Instance
# resource "google_secret_manager_secret_version" "redis_endpoint_version" {
#   secret      = google_secret_manager_secret.redis_endpoint.id
#   secret_data = "${google_redis_instance.cache.host}:${google_redis_instance.cache.port}"
# }

# # Dedicated Service Account for External Secrets Operator (ESO)
# resource "google_service_account" "eso_sa" {
#   account_id   = "${var.env}-external-secrets-sa"
#   display_name = "External Secrets Operator IAM Identity"
#   project      = var.project_id
# }

# # Grant ESO Service Account Access to the Specific Secret
# resource "google_secret_manager_secret_iam_member" "eso_accessor" {
#   project   = var.project_id
#   secret_id = google_secret_manager_secret.redis_endpoint.id # Fixed reference
#   role      = "roles/secretmanager.secretAccessor"
#   member    = "serviceAccount:${google_service_account.eso_sa.email}"
# }

# # Bind GCP IAM Service Account to GKE Kubernetes Service Account via Workload Identity
# resource "google_service_account_iam_member" "eso_workload_identity" {
#   service_account_id = google_service_account.eso_sa.name
#   role               = "roles/iam.workloadIdentityUser"
#   member             = "serviceAccount:${var.project_id}.svc.id.goog[external-secrets/external-secrets-sa]"
# }

# # ==============================================================================
# # Long-Term Observability Storage Engine (CMEK Encrypted)
# # ==============================================================================
# resource "google_storage_bucket" "tempo_store" {
#   name                        = "${var.env}-tempo-backend-${var.project_id}"
#   location                    = var.region
#   force_destroy               = true
#   storage_class               = "STANDARD"
#   uniform_bucket_level_access = true
#   labels                      = local.labels

#   encryption {
#     default_kms_key_name = module.kms.crypto_key_id
#   }

#   lifecycle_rule {
#     condition { age = 7 }
#     action { type = "Delete" }
#   }
# }

# resource "google_storage_bucket" "thanos_store" {
#   name                        = "${var.env}-thanos-store-${var.project_id}"
#   location                    = var.region
#   force_destroy               = true
#   storage_class               = "STANDARD"
#   uniform_bucket_level_access = true
#   labels                      = local.labels

#   encryption {
#     default_kms_key_name = module.kms.crypto_key_id
#   }

#   lifecycle_rule {
#     condition { age = 15 }
#     action {
#       type          = "SetStorageClass"
#       storage_class = "NEARLINE"
#     }
#   }
# }

# # ==============================================================================
# # Observability Workload Identities & GCS IAM Bindings
# # ==============================================================================
# resource "google_service_account" "observability_storage_sa" {
#   account_id   = "${var.env}-observability-storage-sa"
#   display_name = "Telemetry GCS backend identity access"
# }

# resource "google_storage_bucket_iam_member" "tempo_perms" {
#   bucket = google_storage_bucket.tempo_store.name
#   role   = "roles/storage.admin"
#   member = "serviceAccount:${google_service_account.observability_storage_sa.email}"
# }

# resource "google_storage_bucket_iam_member" "thanos_perms" {
#   bucket = google_storage_bucket.thanos_store.name
#   role   = "roles/storage.objectAdmin"
#   member = "serviceAccount:${google_service_account.observability_storage_sa.email}"
# }

# resource "google_service_account_iam_member" "thanos_tempo_workload" {
#   service_account_id = google_service_account.observability_storage_sa.name
#   role               = "roles/iam.workloadIdentityUser"
#   member             = "serviceAccount:${var.project_id}.svc.id.goog[monitoring/thanos-tempo-sa]"
# }

# # ==============================================================================
# # GitOps Engine Service Accounts & Identity Links
# # ==============================================================================
# resource "google_service_account" "argocd_repo_server" {
#   account_id   = "${var.env}-argocd-repo-sa"
#   display_name = "ArgoCD Repo Server Identity"
# }

# resource "google_service_account" "argocd_image_updater" {
#   account_id   = "${var.env}-argocd-updater-sa"
#   display_name = "ArgoCD Image Updater Identity"
# }

# resource "google_project_iam_member" "argocd_artifact_reader" {
#   project = var.project_id
#   role    = "roles/artifactregistry.reader"
#   member  = "serviceAccount:${google_service_account.argocd_repo_server.email}"
# }

# resource "google_project_iam_member" "updater_artifact_reader" {
#   project = var.project_id
#   role    = "roles/artifactregistry.reader"
#   member  = "serviceAccount:${google_service_account.argocd_image_updater.email}"
# }

# resource "google_service_account_iam_member" "argocd_workload_identity" {
#   service_account_id = google_service_account.argocd_repo_server.name
#   role               = "roles/iam.workloadIdentityUser"
#   member             = "serviceAccount:${var.project_id}.svc.id.goog[argocd/argocd-repo-server]"
# }

# resource "google_service_account_iam_member" "updater_workload_identity" {
#   service_account_id = google_service_account.argocd_image_updater.name
#   role               = "roles/iam.workloadIdentityUser"
#   member             = "serviceAccount:${var.project_id}.svc.id.goog[argocd/argocd-image-updater]"
# }

# # ==============================================================================
# # Edge Routing, Global Gateways & DNS Management
# # ==============================================================================
# module "dns" {
#   source = "../../modules/dns"

#   project_id = var.project_id
#   zone_name  = var.dns_zone_name
#   dns_name   = var.dns_domain
# }

# module "certificate_manager" {
#   source = "../../modules/certificate_manager"

#   project_id    = var.project_id
#   dns_zone_name = module.dns.zone_name
#   domain        = trimsuffix(var.dns_domain, ".")
#   cert_map_name = var.cert_map_name
# }

# resource "google_compute_global_address" "gateway" {
#   name         = "${local.name_prefix}-gateway-ip"
#   address_type = "EXTERNAL"
#   labels       = local.labels
# }



# ==============================================================================
# Dynamic Identity Formulation & Standardized Labels
# ==============================================================================
locals {
  name_prefix = "boutique"
  labels = {
    platform = "microservices-google"
    managed  = "terraform"
    env      = var.env
  }
}

data "google_project" "current" {
  project_id = var.project_id
}

# Fetch Cloud Storage System Identity for CMEK Bucket Encryption
data "google_storage_project_service_account" "gcs_account" {
  project = var.project_id
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
    "cloudkms.googleapis.com",
    "certificatemanager.googleapis.com",
    "binaryauthorization.googleapis.com",
    "secretmanager.googleapis.com"
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

  project_id   = var.project_id
  region       = var.region
  network_name = "${local.name_prefix}-vpc"
  subnet_name  = "${local.name_prefix}-gke"

  depends_on = [google_project_service.required_apis]
}

# ==============================================================================
# Enterprise Security Core (Cloud KMS Key Orchestration)
# ==============================================================================
module "kms" {
  source = "../../modules/kms"

  project_id = var.project_id
  region     = var.region
  key_ring   = "${local.name_prefix}-gke"
  env        = var.env
  crypto_key = "etcd-secrets"

  depends_on = [google_project_service.required_apis]
}

# GKE Control Plane service identity mapping for etcd Database Encryption
resource "google_kms_crypto_key_iam_member" "gke_etcd_encryption" {
  crypto_key_id = module.kms.crypto_key_id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${data.google_project.current.number}@container-engine-robot.iam.gserviceaccount.com"
}

# GCS Service Agent identity mapping for CMEK Bucket Encryption (Tempo & Thanos)
resource "google_kms_crypto_key_iam_member" "gcs_kms_encrypter_decrypter" {
  crypto_key_id = module.kms.crypto_key_id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}"
}

# ==============================================================================
# GKE Compute Cluster Layer with Binary Authorization
# ==============================================================================
module "gke" {
  source = "../../modules/gke"

  project_id                 = var.project_id
  env                        = var.env
  region                     = var.region
  cluster_name               = var.cluster_name
  network                    = module.network.network_name
  subnetwork                 = module.network.subnetwork_name
  pods_range_name            = module.network.pods_range_name
  services_range_name        = module.network.services_range_name
  master_authorized_networks = var.master_authorized_networks
  kms_key_id                 = module.kms.crypto_key_id

  depends_on = [
    google_project_service.required_apis,
    google_kms_crypto_key_iam_member.gke_etcd_encryption
  ]
}

resource "google_project_iam_member" "gke_nodes_artifact_registry_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

# Explicitly defining monitoring/logging permissions natively required by GKE Node Pools
resource "google_project_iam_member" "node_telemetry_roles" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/stackdriver.resourceMetadata.writer",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer"
  ])

  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

# ==============================================================================
# Supply Chain Security & Attestation Core
# ==============================================================================
module "binary_auth" {
  source = "../../modules/binary_auth"

  project_id = var.project_id
  depends_on = [google_project_service.required_apis]
}

resource "google_binary_authorization_attestor_iam_member" "build_ci_attestor" {
  project  = var.project_id
  attestor = "boutique-cosign"
  role     = "roles/binaryauthorization.attestorsViewer"
  member   = "serviceAccount:${google_service_account.build_ci.email}"
}

# ==============================================================================
# Managed Artifact Architecture & CI/CD Promotional Entitlements
# ==============================================================================
module "custom_artifact_registry" {
  source = "../../modules/artifact_registry"

  project_id        = var.project_id
  region            = var.region
  environment       = var.env
  docker_registries = var.docker_registries
}

# Dynamic RBAC assignments across all configured registries in var.docker_registries
resource "google_artifact_registry_repository_iam_member" "build_ci_writer" {
  for_each   = toset(var.docker_registries)
  project    = var.project_id
  location   = var.region
  repository = "${var.env}-${each.key}"
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${google_service_account.build_ci.email}"
  depends_on = [module.custom_artifact_registry]
}

resource "google_artifact_registry_repository_iam_member" "promote_ci_reader" {
  for_each   = toset(var.docker_registries)
  project    = var.project_id
  location   = var.region
  repository = "${var.env}-${each.key}"
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${google_service_account.promote_ci.email}"
  depends_on = [module.custom_artifact_registry]
}

resource "google_artifact_registry_repository_iam_member" "promote_ci_writer" {
  for_each   = toset(var.docker_registries)
  project    = var.project_id
  location   = var.region
  repository = "${var.env}-${each.key}"
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${google_service_account.promote_ci.email}"
  depends_on = [module.custom_artifact_registry]
}

# ==============================================================================
# SERVICE ACCOUNTS
# ==============================================================================
resource "google_service_account" "gke_nodes" {
  account_id   = var.sa-gke-nodes
  display_name = "Dedicated GKE Node System Account"
  project      = var.project_id
}

resource "google_service_account" "build_ci" {
  account_id   = var.build_ci_sa_name
  display_name = "GitHub Actions CI Build Agent"
  project      = var.project_id
}

resource "google_service_account" "promote_ci" {
  account_id   = var.promote_ci_sa_name
  display_name = "GitHub Actions CI Release Promotion Agent"
  project      = var.project_id
}

# ==============================================================================
# Managed Cloud Memorystore Redis
# ==============================================================================
resource "google_compute_global_address" "redis_private_ip_range" {
  name          = "${local.name_prefix}-redis-private-ip"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = module.network.network_name
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = module.network.network_name
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.redis_private_ip_range.name]
  deletion_policy         = "ABANDON"
}

resource "google_redis_instance" "cache" {
  name           = "${var.env}-online-boutique-cache"
  tier           = "STANDARD_HA"
  memory_size_gb = 5
  region         = var.region

  authorized_network = module.network.network_name
  connect_mode       = "PRIVATE_SERVICE_ACCESS"
  redis_version      = "REDIS_7_0"

  labels = local.labels

  depends_on = [google_service_networking_connection.private_vpc_connection]
}

# ==============================================================================
# GCP Secret Manager & External Secrets Operator Integration
# ==============================================================================

# Secret Container for Memorystore Redis Connection String
resource "google_secret_manager_secret" "redis_endpoint" {
  project   = var.project_id
  secret_id = "redis-endpoint-${var.env}"

  replication {
    auto {}
  }

  labels = local.labels

  depends_on = [google_project_service.required_apis]
}

# Create Secret Version sourcing from the Redis Instance
resource "google_secret_manager_secret_version" "redis_endpoint_version" {
  secret      = google_secret_manager_secret.redis_endpoint.id
  secret_data = "${google_redis_instance.cache.host}:${google_redis_instance.cache.port}"
}

# Dedicated Service Account for External Secrets Operator (ESO)
resource "google_service_account" "eso_sa" {
  account_id   = "${var.env}-external-secrets-sa"
  display_name = "External Secrets Operator IAM Identity"
  project      = var.project_id
}

# Grant ESO Service Account Access to the Specific Secret
resource "google_secret_manager_secret_iam_member" "eso_accessor" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.redis_endpoint.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.eso_sa.email}"
}

# Bind GCP IAM Service Account to GKE Kubernetes Service Account via Workload Identity
resource "google_service_account_iam_member" "eso_workload_identity" {
  service_account_id = google_service_account.eso_sa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[external-secrets/external-secrets-sa]"
}

# ==============================================================================
# Long-Term Observability Storage Engine (CMEK Encrypted)
# ==============================================================================
resource "google_storage_bucket" "tempo_store" {
  name                        = "${var.env}-tempo-backend-${var.project_id}"
  location                    = var.region
  force_destroy               = true
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  labels                      = local.labels

  encryption {
    default_kms_key_name = module.kms.crypto_key_id
  }

  lifecycle_rule {
    condition { age = 7 }
    action { type = "Delete" }
  }

  depends_on = [google_kms_crypto_key_iam_member.gcs_kms_encrypter_decrypter]
}

resource "google_storage_bucket" "thanos_store" {
  name                        = "${var.env}-thanos-store-${var.project_id}"
  location                    = var.region
  force_destroy               = true
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  labels                      = local.labels

  encryption {
    default_kms_key_name = module.kms.crypto_key_id
  }

  lifecycle_rule {
    condition { age = 15 }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  depends_on = [google_kms_crypto_key_iam_member.gcs_kms_encrypter_decrypter]
}

# ==============================================================================
# Observability Workload Identities & GCS IAM Bindings
# ==============================================================================
resource "google_service_account" "observability_storage_sa" {
  account_id   = "${var.env}-observability-storage-sa"
  display_name = "Telemetry GCS backend identity access"
  project      = var.project_id
}

resource "google_storage_bucket_iam_member" "tempo_perms" {
  bucket = google_storage_bucket.tempo_store.name
  role   = "roles/storage.admin"
  member = "serviceAccount:${google_service_account.observability_storage_sa.email}"
}

resource "google_storage_bucket_iam_member" "thanos_perms" {
  bucket = google_storage_bucket.thanos_store.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.observability_storage_sa.email}"
}

resource "google_service_account_iam_member" "thanos_tempo_workload" {
  service_account_id = google_service_account.observability_storage_sa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[monitoring/thanos-tempo-sa]"
}

# ==============================================================================
# GitOps Engine Service Accounts & Identity Links
# ==============================================================================
resource "google_service_account" "argocd_repo_server" {
  account_id   = "${var.env}-argocd-repo-sa"
  display_name = "ArgoCD Repo Server Identity"
  project      = var.project_id
}

resource "google_service_account" "argocd_image_updater" {
  account_id   = "${var.env}-argocd-updater-sa"
  display_name = "ArgoCD Image Updater Identity"
  project      = var.project_id
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

# ==============================================================================
# Edge Routing, Global Gateways & DNS Management
# ==============================================================================
module "dns" {
  source = "../../modules/dns"

  project_id = var.project_id
  zone_name  = var.dns_zone_name
  dns_name   = var.dns_domain
}

module "certificate_manager" {
  source = "../../modules/certificate_manager"

  project_id    = var.project_id
  dns_zone_name = module.dns.zone_name
  domain        = trimsuffix(var.dns_domain, ".")
  cert_map_name = var.cert_map_name
}

resource "google_compute_global_address" "gateway" {
  name         = "${local.name_prefix}-gateway-ip"
  address_type = "EXTERNAL"
  labels       = local.labels
  project      = var.project_id
}