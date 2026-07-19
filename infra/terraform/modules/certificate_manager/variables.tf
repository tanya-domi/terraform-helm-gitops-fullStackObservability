# ==============================================================================
# 1. VARIABLE DECLARATIONS (INPUT SCHEMAS)
# ==============================================================================
variable "project_id" {
  type        = string
  description = "The target Google Cloud Project ID"
}

variable "domain" {
  type        = string
  description = "The primary apex domain (e.g., example.com) used for cert routing"
}

variable "dns_zone_name" {
  type        = string
  description = "The name of the pre-existing Cloud DNS Managed Zone mapping this domain"
}

variable "cert_map_name" {
  type        = string
  description = "Must match gitops/platform/gateway.yaml networking.gke.io/certmap"
  default     = "boutique-cert-map"
}
