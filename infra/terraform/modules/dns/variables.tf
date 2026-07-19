# variable "project_id"        { type = string }
# variable "zone_name"         { type = string }
# variable "subdomain"         { type = string } # e.g., "dev"
# variable "target_ip_address" { type = string } # Passed from the global-ip resource


variable "project_id" {
  type        = string
  description = "The target Google Cloud Project ID."
}

variable "zone_name" {
  type        = string
  description = "The internal GCP alphanumeric resource identifier for the DNS zone."
}

variable "dns_name" {
  type        = string
  description = "The fully qualified absolute domain suffix ending with a trailing dot."
}