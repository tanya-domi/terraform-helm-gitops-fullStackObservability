# output "tfstate_bucket" {
#   description = "The globally unique name for the remote GCS state bucket."
#   value       = var.bucket
# }

# output "workload_identity_provider_id" {
#   description = "The full identifier for the GitHub Workload Identity Provider"
#   value       = google_iam_workload_identity_pool_provider.github_provider.name
# }

# output "terraform_ci_sa_email" {
#   description = "The email of the core infrastructure deployment service account"
#   value       = google_service_account.infra_deployer.email
# }

# output "build_ci_sa_email" {
#   description = "The email of the application artifact builder/pusher service account"
#   value       = google_service_account.app_pusher.email
# }

# output "wif_pool_id" {
#   description = "The fully qualified resource path for the Workload Identity Pool."
#   value       = google_iam_workload_identity_pool.github_pool.id
# }

# output "wif_provider" {
#   description = "The canonical Workload Identity Provider resource identifier needed for GitHub OIDC authentication."
#   value       = google_iam_workload_identity_pool_provider.github_provider.name
# }

# output "promote_ci_sa_email" {
#   description = "The IAM Service Account email used to promote Helm configurations across GitOps tracks."
#   value       = google_service_account.app_pusher.email
# }

# output "terraform_sa_email" {
#   description = "Infrastructure Deployer Service Account Email"
#   value       = google_service_account.terraform_ci.email
# }

# output "build_sa_email" {
#   description = "Application Artifact Builder Service Account Email"
#   value       = google_service_account.build_ci.email
# }

# output "promote_sa_email" {
#   description = "Image Cross-Registry Promoter Service Account Email"
#   value       = google_service_account.promote_ci.email
# }

# output "wif_provider" {
#   description = "Fully Qualified Workload Identity Pool Provider Identifier"
#   value       = google_iam_workload_identity_pool_provider.github_provider.name
# }

# output "bucket_name" {
#   description = "Hardened GCS Remote Backend Terraform State Bucket Name"
#   value       = google_storage_bucket.terraform_state.name
# }




output "tfstate_bucket" {
  description = "The globally unique name for the remote GCS state bucket."
  value       = google_storage_bucket.terraform_state.name
}


output "wif_pool_id" {
  description = "The fully qualified resource path for the Workload Identity Pool."
  value       = google_iam_workload_identity_pool.github_pool.id
}

output "wif_provider" {
  description = "The canonical Workload Identity Provider resource identifier needed for GitHub OIDC authentication."
  value       = google_iam_workload_identity_pool_provider.github_provider.name
}

output "terraform_sa_email" {
  description = "The IAM Service Account email for core infrastructure deployments."
  value       = google_service_account.infra_deployer.email
}

output "build_sa_email" {
  description = "The IAM Service Account email for building and pushing application artifacts."
  value       = google_service_account.app_pusher.email
}

output "promote_sa_email" {
  description = "The IAM Service Account email used to promote artifacts across registries."
  value       = google_service_account.app_promoter.email
}