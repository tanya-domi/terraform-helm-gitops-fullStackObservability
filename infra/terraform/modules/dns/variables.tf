variable "project_id"        { type = string }
variable "zone_name"         { type = string }
variable "subdomain"         { type = string } # e.g., "dev"
variable "target_ip_address" { type = string } # Passed from the global-ip resource