variable "project_id" {
  type        = string
  description = "The target Google Cloud Project ID."
}

variable "region" {
  type        = string
  default     = "us-central1"
  description = "Default GCP region for bootstrap resources."
}

variable "bucket" {
  type        = string
  description = "The globally unique name for the remote GCS state bucket."
}

variable "github_token" {
  type        = string
  sensitive   = true
  description = "GitHub Personal Access Token (PAT) used to provision repository secrets."
}

variable "github_repos" {
  type    = list(string)
  default = [
    "tanya-domi/terraform-helm-gitops-fullStackObservability"
  ]
}

variable "docker_registries" {
  type    = list(string)
  default = ["app-images", "helm-charts"]
}