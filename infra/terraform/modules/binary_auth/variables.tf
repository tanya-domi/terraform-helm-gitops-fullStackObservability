variable "project_id" {
  type        = string
  description = "The target GCP project ID where Binary Authorization resources live"
}

variable "env" {
  type        = string
  description = "The environment designation (e.g. dev, prod)"
  default     = "dev"
}