# # Create Core Multi-Environment State Container
# resource "google_storage_bucket" "terraform_state" {
#   name                        = var.bucket
#   location                    = var.region
#   force_destroy               = false # Protect production state records
#   storage_class               = "STANDARD"
#   uniform_bucket_level_access = true

#   versioning {
#     enabled = true
#   }

#   lifecycle_rule {
#     condition {
#       age = 365
#     }
#     action {
#       type = "Delete"
#     }
#   }
# }

# # Core Pipeline Automation Identity
# resource "google_service_account" "github_actions_pusher" {
#   account_id   = "github-actions-pusher"
#   display_name = "GitHub Actions Engine Automation"
# }

# # Workload Identity Federation Federation Pool
# resource "google_iam_workload_identity_pool" "github_pool" {
#   workload_identity_pool_id = "github-actions-pool-v2"
#   display_name              = "GitHub Actions Pool V2"
#   description               = "Secure OIDC integration tracking GitHub runner workloads"
# }

# resource "google_iam_workload_identity_pool_provider" "github_provider" {
#   workload_identity_pool_id          = google_iam_workload_identity_pool.github_pool.workload_identity_pool_id
#   workload_identity_pool_provider_id = "github-provider"

#   attribute_mapping = {
#     "google.subject"       = "assertion.sub"
#     "attribute.repository" = "assertion.repository"
#     "attribute.owner"      = "assertion.repository_owner"
#   }

#   attribute_condition = "assertion.repository_owner == 'tanya-domi'"

#   oidc {
#     issuer_uri = "https://token.actions.githubusercontent.com"
#   }
# }

# # Secure Cryptographic Handshake Link to target Repository
# resource "google_service_account_iam_member" "oidc_auth" {
#   service_account_id = google_service_account.github_actions_pusher.name
#   role               = "roles/iam.workloadIdentityUser"
#   member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool.name}/attribute.repository/tanya-domi/Full-Stack-Observability-for-Microservices"
# }

# # Inject metadata straight back into the Repository Actions context
# resource "github_actions_secret" "gcp_secrets" {
#   for_each = {
#     "GCP_WORKLOAD_IDENTITY_PROVIDER" = google_iam_workload_identity_pool_provider.github_provider.name
#     "GCP_SERVICE_ACCOUNT_EMAIL"      = google_service_account.github_actions_pusher.email
#   }

#   repository      = "Full-Stack-Observability-for-Microservices"
#   secret_name     = each.key
#   value           = each.value
# }


# ==============================================================================
# 1. STATE MANAGEMENT FOUNDATION
# ==============================================================================

# Create Core Multi-Environment State Container
resource "google_storage_bucket" "terraform_state" {
  name                        = var.bucket
  location                    = var.region
  force_destroy               = false # Protect production state records
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = 365
    }
    action {
      type = "Delete"
    }
  }
}

# ==============================================================================
# 2. INDEPENDENT PRODUCTION SERVICE ACCOUNTS (LEAST PRIVILEGE)
# ==============================================================================

# Account A: Manages core infrastructure rollouts (VPC, GKE, KMS) via foundation repo
resource "google_service_account" "infra_deployer" {
  account_id   = "github-actions-infra-sa"
  display_name = "GitHub Actions Infrastructure Deployer (Prod)"
}

# Account B: Handles application build pipelines (Docker/Helm artifact pushes) via application repo
resource "google_service_account" "app_pusher" {
  account_id   = "github-actions-app-sa"
  display_name = "GitHub Actions Application Artifact Pusher"
}

# ==============================================================================
# 3. RBAC SECURITY ASSIGNMENTS (IAM)
# ==============================================================================

# Grant full project control strictly to the Infrastructure Deployer Service Account
resource "google_project_iam_member" "infra_owner" {
  project = var.project_id
  role    = "roles/owner"
  member  = "serviceAccount:${google_service_account.infra_deployer.email}"
}

# This breaks the dependency cycle so bootstrap can apply without the registries existing yet.
resource "google_project_iam_member" "project_artifact_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.app_pusher.email}"
}

# ==============================================================================
# 4. WORKLOAD IDENTITY FEDERATION ENGINE (OIDC POOL)
# ==============================================================================

resource "google_iam_workload_identity_pool" "github_pool" {
  workload_identity_pool_id = "github-actions-pool-v3" # Upgraded to version 3
  display_name              = "GitHub Actions Pool V3"
  description               = "Secure OIDC authentication engine for GitHub Actions"
}

resource "google_iam_workload_identity_pool_provider" "github_provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
    "attribute.owner"      = "assertion.repository_owner"
  }

  attribute_condition = "assertion.repository_owner == 'tanya-domi'"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# ==============================================================================
# 5. BACK-TO-BACK REPOSITORY BINDINGS (OIDC AUTH STRUCTURE)
# ==============================================================================

# Bind the Infrastructure Repo to the Infrastructure Deployer SA
resource "google_service_account_iam_member" "infra_oidc_auth" {
  service_account_id = google_service_account.infra_deployer.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool.name}/attribute.repository/tanya-domi/terraform-helm-gitops-fullStackObservability"
}

# Bind the Microservices Application Repo to the Application Artifact Pusher SA
resource "google_service_account_iam_member" "app_oidc_auth" {
  service_account_id = google_service_account.app_pusher.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool.name}/attribute.repository/tanya-domi/Full-Stack-Observability-for-Microservices"
}

# ==============================================================================
# 6. AUTOMATED DYNAMIC GITHUB SECRETS PROVISIONING
# ==============================================================================

locals {
  # Layout the structural secrets roadmap per target project repository context
  secrets_configuration = {
    "terraform-helm-gitops-fullStackObservability" = {
      "GCP_WIF_PROVIDER"       = google_iam_workload_identity_pool_provider.github_provider.name
      "GCP_TERRAFORM_SA_EMAIL" = google_service_account.infra_deployer.email
    }
    "Full-Stack-Observability-for-Microservices" = {
      "GCP_WIF_PROVIDER"   = google_iam_workload_identity_pool_provider.github_provider.name
      "GCP_BUILD_SA_EMAIL" = google_service_account.app_pusher.email
    }
  }

  # Flatten map configurations into an explicit schema structure for for_each loops
  flattened_secrets = merge([
    for repo_name, secret_map in local.secrets_configuration : {
      for secret_key, secret_val in secret_map : "${repo_name}.${secret_key}" => {
        repo        = repo_name
        secret_name = secret_key
        value       = secret_val
      }
    }
  ]...)
}

resource "github_actions_secret" "gcp_secrets" {
  for_each        = local.flattened_secrets
  repository      = each.value.repo
  secret_name     = each.value.secret_name
  value           = each.value.value
}