


variable "project_id" {
  type        = string
  description = "The GCP Project ID."
}

variable "region" {
  type        = string
  description = "GCP region to provision infrastructure."
}

variable "environment" {
  type        = string
  description = "Deployment landscape name (e.g., prod, dev)."
}

variable "docker_registries" {
  type        = list(string)
  description = "List of artifact repository identifiers to provision."
  default = ["app-images", "helm-charts"]
}

variable "cleanup_keep_count" {
  type    = number
  default = 30
}

variable "cleanup_older_than" {
  type    = string
  default = "7776000s" # 90 days
}

variable "github_pusher_email" {
  description = "Service account email for CI/CD pusher"
  type        = string
  default     = null # 
}