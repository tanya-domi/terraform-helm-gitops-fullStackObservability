

# # ==============================================================================
# # 1. STATE MANAGEMENT FOUNDATION
# # ==============================================================================

# locals {
#   name_prefix = "boutique"
#   labels = {
#     platform    = "microservices-google"
#     managed     = "terraform"
#     environment = var.environment
#   }
# }

# # Create Core Multi-Environment State Container
# resource "google_storage_bucket" "terraform_state" {
#   name                        = var.bucket
#   location                    = var.region
#   force_destroy               = false # Fixed: Set to false to protect production state records
#   storage_class               = "STANDARD"
#   uniform_bucket_level_access = true
#   public_access_prevention    = "enforced" # Added: Drops all public access vectors

#   versioning {
#     enabled = true
#   }

#   lifecycle_rule {
#     condition {
#       num_newer_versions = 10 # Enhanced: Deletes older versions instead of strict age limits
#     }
#     action {
#       type = "Delete"
#     }
#   }

#   labels = local.labels # Added: Metadata tracking labels
# }


# # ==============================================================================
# # 2. INDEPENDENT PRODUCTION SERVICE ACCOUNTS (LEAST PRIVILEGE)
# # ==============================================================================

# # Account A: Manages core infrastructure rollouts (VPC, GKE, KMS) via foundation repo
# resource "google_service_account" "infra_deployer" {
#   account_id   = "sa-${local.name_prefix}-terraform-ci"
#   display_name = "GitHub Actions Infrastructure Deployer (Prod)"
# }

# # Account B: Handles application build pipelines (Docker/Helm artifact pushes) via application repo
# resource "google_service_account" "app_pusher" {
#   account_id   = "sa-${local.name_prefix}-build-ci"
#   display_name = "GitHub Actions Application Artifact Pusher"
# }

# # Account C: Promotes images across Artifact Registry environments via application repo
# resource "google_service_account" "app_promoter" {
#   account_id   = "sa-${local.name_prefix}-promote-ci"
#   display_name = "GitHub Actions Image Release Promoter"
# }

# # ==============================================================================
# # 3. RBAC SECURITY ASSIGNMENTS (IAM)
# # ==============================================================================

# # Grant full project control strictly to the Infrastructure Deployer Service Account
# resource "google_project_iam_member" "infra_owner" {
#   project = var.project_id
#   role    = "roles/owner"
#   member  = "serviceAccount:${google_service_account.infra_deployer.email}"
# }

# # Grant state bucket administrative rights to the Infrastructure Deployer Service Account
# resource "google_storage_bucket_iam_member" "infra_state_admin" {
#   bucket = google_storage_bucket.terraform_state.name
#   role   = "roles/storage.objectAdmin"
#   member = "serviceAccount:${google_service_account.infra_deployer.email}"
# }

# # Breaks dependency cycle so bootstrap can apply before registries exist
# resource "google_project_iam_member" "project_artifact_writer" {
#   project = var.project_id
#   role    = "roles/artifactregistry.writer"
#   member  = "serviceAccount:${google_service_account.app_pusher.email}"
# }

# # Grants cross-registry orchestration capabilities to the Promoter Service Account
# resource "google_project_iam_member" "project_artifact_admin" {
#   project = var.project_id
#   role    = "roles/artifactregistry.repoAdmin"
#   member  = "serviceAccount:${google_service_account.app_promoter.email}"
# }


# resource "google_storage_bucket_iam_member" "tf_sa_storage_admin" {
#   bucket = var.bucket
#   role   = "roles/storage.objectAdmin"
#   member = "serviceAccount:sa-boutique-terraform-ci@project-1cdbea51-6334-4e02-967.iam.gserviceaccount.com"
# }
# # ==============================================================================
# # 4. WORKLOAD IDENTITY FEDERATION ENGINE (OIDC POOL)
# # ==============================================================================

# resource "google_iam_workload_identity_pool" "github_pool" {
#   workload_identity_pool_id = "${local.name_prefix}-github-pool-v3"
#   display_name              = "GitHub Actions Pool V3"
#   description               = "Secure OIDC authentication engine for GitHub Actions"
# }

# resource "google_iam_workload_identity_pool_provider" "github_provider" {
#   workload_identity_pool_id          = google_iam_workload_identity_pool.github_pool.workload_identity_pool_id
#   workload_identity_pool_provider_id = "github-provider"

#   attribute_mapping = {
#     "google.subject"       = "assertion.sub"
#     "attribute.repository" = "assertion.repository"
#     "attribute.owner"      = "assertion.repository_owner"
#     "attribute.ref"        = "assertion.ref"   # Added: Exposes branch context
#     "attribute.actor"      = "assertion.actor" # Added: Exposes runtime workflow runner identity
#   }

#   attribute_condition = "assertion.repository_owner == 'tanya-domi'"

#   oidc {
#     issuer_uri = "https://token.actions.githubusercontent.com"
#   }
# }

# # ==============================================================================
# # 5. BACK-TO-BACK REPOSITORY BINDINGS (OIDC AUTH STRUCTURE)
# # ==============================================================================

# locals {
#   infra_wif_member = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool.name}/attribute.repository/tanya-domi/terraform-helm-gitops-fullStackObservability"
#   app_wif_member   = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool.name}/attribute.repository/tanya-domi/Full-Stack-Observability-for-Microservices"
# }

# # Bind the Infrastructure Repo to the Infrastructure Deployer SA
# resource "google_service_account_iam_member" "infra_oidc_auth" {
#   service_account_id = google_service_account.infra_deployer.name
#   role               = "roles/iam.workloadIdentityUser"
#   member             = local.infra_wif_member
# }

# # Bind the Microservices Application Repo to the Application Artifact Pusher SA
# resource "google_service_account_iam_member" "app_oidc_auth" {
#   service_account_id = google_service_account.app_pusher.name
#   role               = "roles/iam.workloadIdentityUser"
#   member             = local.app_wif_member
# }

# # Bind the Microservices Application Repo to the Application Artifact Promoter SA
# resource "google_service_account_iam_member" "app_promote_oidc_auth" {
#   service_account_id = google_service_account.app_promoter.name
#   role               = "roles/iam.workloadIdentityUser"
#   member             = local.app_wif_member
# }

# # ==============================================================================
# # 6. AUTOMATED DYNAMIC GITHUB SECRETS PROVISIONING
# # ==============================================================================

# locals {
#   # Layout the structural secrets roadmap per target project repository context
#   secrets_configuration = {
#     "terraform-helm-gitops-fullStackObservability" = {
#       "GCP_WIF_PROVIDER"       = google_iam_workload_identity_pool_provider.github_provider.name
#       "GCP_TERRAFORM_SA_EMAIL" = google_service_account.infra_deployer.email
#     }
#     "Full-Stack-Observability-for-Microservices" = {
#       "GCP_WIF_PROVIDER"     = google_iam_workload_identity_pool_provider.github_provider.name
#       "GCP_BUILD_SA_EMAIL"   = google_service_account.app_pusher.email
#       "GCP_PROMOTE_SA_EMAIL" = google_service_account.app_promoter.email # Added: Promotion SA injection
#     }
#   }

#   # Flatten map configurations into an explicit schema structure for for_each loops
#   flattened_secrets = merge([
#     for repo_name, secret_map in local.secrets_configuration : {
#       for secret_key, secret_val in secret_map : "${repo_name}.${secret_key}" => {
#         repo        = repo_name
#         secret_name = secret_key
#         value       = secret_val
#       }
#     }
#   ]...)
# }

# resource "github_actions_secret" "gcp_secrets" {
#   for_each    = local.flattened_secrets
#   repository  = each.value.repo
#   secret_name = each.value.secret_name
#   value       = each.value.value
# }



# # ==============================================================================
# # 7. PROGRAMMATIC COST CONTROLS (BILLING BUDGET)
# # ==============================================================================

# resource "google_billing_budget" "platform" {
#   count           = var.billing_account_id != "" && var.monthly_budget_usd > 0 ? 1 : 0
#   billing_account = var.billing_account_id
#   display_name    = "${local.name_prefix}-monthly-budget"

#   budget_filter {
#     projects = ["projects/${var.project_id}"]
#   }

#   amount {
#     specified_amount {
#       currency_code = "USD"
#       units         = tostring(var.monthly_budget_usd)
#     }
#   }

#   threshold_rules {
#     threshold_percent = 0.5
#   }
#   threshold_rules {
#     threshold_percent = 0.9
#   }
#   threshold_rules {
#     threshold_percent = 1.0
#   }
# }




locals {
  name_prefix = "boutique"
  labels = {
    platform    = "microservices-google"
    managed     = "terraform"
    environment = var.environment
  }
}

# Create Core Multi-Environment State Container
resource "google_storage_bucket" "terraform_state" {
  name                        = var.bucket
  location                    = var.region
  force_destroy               = false
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      num_newer_versions = 10
    }
    action {
      type = "Delete"
    }
  }

  labels = local.labels
}

# ==============================================================================
# 2. INDEPENDENT PRODUCTION SERVICE ACCOUNTS (LEAST PRIVILEGE)
# ==============================================================================

# Account A: Manages core infrastructure rollouts (VPC, GKE, KMS) via foundation repo
resource "google_service_account" "infra_deployer" {
  account_id   = "sa-${local.name_prefix}-terraform-ci"
  display_name = "GitHub Actions Infrastructure Deployer (Prod)"
}

# Account B: Handles application build pipelines (Docker/Helm artifact pushes) via application repo
resource "google_service_account" "app_pusher" {
  account_id   = "sa-${local.name_prefix}-build-ci"
  display_name = "GitHub Actions Application Artifact Pusher"
}

# Account C: Promotes images across Artifact Registry environments via application repo
resource "google_service_account" "app_promoter" {
  account_id   = "sa-${local.name_prefix}-promote-ci"
  display_name = "GitHub Actions Image Release Promoter"
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

# Grant state bucket administrative rights to the Infrastructure Deployer Service Account
resource "google_storage_bucket_iam_member" "infra_state_admin" {
  bucket = google_storage_bucket.terraform_state.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.infra_deployer.email}"
}

# Grant state bucket administrative rights to the Build CI Service Account
resource "google_storage_bucket_iam_member" "app_pusher_state_admin" {
  bucket = google_storage_bucket.terraform_state.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.app_pusher.email}"
}

# Grant state bucket administrative rights to the Promote CI Service Account
resource "google_storage_bucket_iam_member" "app_promoter_state_admin" {
  bucket = google_storage_bucket.terraform_state.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.app_promoter.email}"
}

# Breaks dependency cycle so bootstrap can apply before registries exist
resource "google_project_iam_member" "project_artifact_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.app_pusher.email}"
}

# Grants cross-registry orchestration capabilities to the Promoter Service Account
resource "google_project_iam_member" "project_artifact_admin" {
  project = var.project_id
  role    = "roles/artifactregistry.repoAdmin"
  member  = "serviceAccount:${google_service_account.app_promoter.email}"
}

# Authorize the OIDC principal group pool directly on the bucket 
resource "google_storage_bucket_iam_member" "infra_state_wif_admin" {
  bucket = google_storage_bucket.terraform_state.name
  role   = "roles/storage.objectAdmin"
  member = local.infra_wif_member # Optimized to use your clean local variable
}

# ==============================================================================
# 4. WORKLOAD IDENTITY FEDERATION ENGINE (OIDC POOL)
# ==============================================================================

resource "google_iam_workload_identity_pool" "github_pool" {
  workload_identity_pool_id = "${local.name_prefix}-github-pool-v3"
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
    "attribute.ref"        = "assertion.ref"
    "attribute.actor"      = "assertion.actor"
  }

  attribute_condition = "assertion.repository_owner == 'tanya-domi'"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# ==============================================================================
# 5. BACK-TO-BACK REPOSITORY BINDINGS (OIDC AUTH STRUCTURE)
# ==============================================================================

locals {
  infra_wif_member = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool.name}/attribute.repository/tanya-domi/terraform-helm-gitops-fullStackObservability"
  app_wif_member   = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool.name}/attribute.repository/tanya-domi/Full-Stack-Observability-for-Microservices"
}

# Bind the Infrastructure Repo to the Infrastructure Deployer SA
resource "google_service_account_iam_member" "infra_oidc_auth" {
  service_account_id = google_service_account.infra_deployer.name
  role               = "roles/iam.workloadIdentityUser"
  member             = local.infra_wif_member
}

# Bind the Microservices Application Repo to the Application Artifact Pusher SA
resource "google_service_account_iam_member" "app_oidc_auth" {
  service_account_id = google_service_account.app_pusher.name
  role               = "roles/iam.workloadIdentityUser"
  member             = local.app_wif_member
}

# Bind the Microservices Application Repo to the Application Artifact Promoter SA
resource "google_service_account_iam_member" "app_promote_oidc_auth" {
  service_account_id = google_service_account.app_promoter.name
  role               = "roles/iam.workloadIdentityUser"
  member             = local.app_wif_member
}

# ==============================================================================
# 6. AUTOMATED DYNAMIC GITHUB SECRETS PROVISIONING
# ==============================================================================

locals {
  secrets_configuration = {
    "terraform-helm-gitops-fullStackObservability" = {
      "GCP_WIF_PROVIDER"  = google_iam_workload_identity_pool_provider.github_provider.name
      "GCP_BUILD_SA"      = google_service_account.app_pusher.email
      "GCP_PROMOTE_SA"    = google_service_account.app_promoter.email
      "GCP_TERRAFORM_SA"  = google_service_account.infra_deployer.email # CRITICAL FIX: Maps SA to foundation runner
    }
    "Full-Stack-Observability-for-Microservices" = {
      "GCP_WIF_PROVIDER"  = google_iam_workload_identity_pool_provider.github_provider.name
      "GCP_BUILD_SA"      = google_service_account.app_pusher.email
      "GCP_PROMOTE_SA"    = google_service_account.app_promoter.email
    }
  }

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
  for_each    = local.flattened_secrets
  repository  = each.value.repo
  secret_name = each.value.secret_name
  value       = each.value.value
}

# ==============================================================================
# 7. PROGRAMMATIC COST CONTROLS (BILLING BUDGET)
# ==============================================================================

resource "google_billing_budget" "platform" {
  count           = var.billing_account_id != "" && var.monthly_budget_usd > 0 ? 1 : 0
  billing_account = var.billing_account_id
  display_name    = "${local.name_prefix}-monthly-budget"

  budget_filter {
    projects = ["projects/${var.project_id}"]
  }

  amount {
    specified_amount {
      currency_code = "USD"
      units         = tostring(var.monthly_budget_usd)
    }
  }

  threshold_rules {
    threshold_percent = 0.5
  }
  threshold_rules {
    threshold_percent = 0.9
  }
  threshold_rules {
    threshold_percent = 1.0
  }
}