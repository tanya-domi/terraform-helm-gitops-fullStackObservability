variable "project_id" {
  type        = string
  description = "The target Google Cloud Project ID."
}

variable "region" {
  type        = string
  description = "GCP regional anchor for storage buckets and cloud infrastructure."
}

variable "env" {
  type        = string
  description = "Target deployment environment lifecycle (e.g., dev, stage, prod)."
}