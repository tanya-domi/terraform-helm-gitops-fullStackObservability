# variable "project_id" {
#   type        = string
#   description = "The target Google Cloud Project ID."
# }

# variable "region" {
#   type        = string
#   default     = "us-central1"
#   description = "Default GCP region for bootstrap resources."
# }

# variable "bucket" {
#   type        = string
#   description = "The globally unique name for the remote GCS state bucket."
# }

# variable "github_token" {
#   type        = string
#   sensitive   = true
#   description = "GitHub Personal Access Token (PAT) used to provision repository secrets."
# }

# variable "github_repos" {
#   type    = list(string)
#   default = [
#     "tanya-domi/terraform-helm-gitops-fullStackObservability"
#   ]
# }

# variable "docker_registries" {
#   type    = list(string)
#   default = ["app-images", "helm-charts"]
# }

# ==============================================================================
# CORE GCP TARGET PARAMETERS
# ==============================================================================

variable "project_id" {
  type        = string
  description = "The target Google Cloud Project ID where core infrastructure will reside."
}

variable "region" {
  type        = string
  default     = "us-central1"
  description = "Default GCP compute and storage region for bootstrap resources."
}

variable "bucket" {
  type        = string
  description = "The globally unique name for the remote GCS state bucket."
}

variable "environment" {
  type        = string
  default     = "production"
  description = "Target environment tier used for tagging, metadata, and state isolation labels."
}

variable "github_token" {
  type        = string
  sensitive   = true
  description = "GitHub Personal Access Token (PAT) with administration/secrets write permissions used to provision repository secrets."
}

variable "billing_account_id" {
  type        = string
  default     = ""
  description = "The Alphanumeric GCP Billing Account ID (e.g., 012345-6789AB-CDEF01). If left blank, budget creation is skipped."
}

variable "monthly_budget_usd" {
  type        = number
  default     = 0
  description = "The total hard ceiling budget allowance per month in USD. Disabled if set to 0."
}