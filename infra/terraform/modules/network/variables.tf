# variable "env" {
#   type        = string
#   description = "Target deployment environment (e.g. dev, stage, prod)"
# }

# variable "region" {
#   type        = string
#   description = "GCP region for subnets and routing"
# }

# variable "vpc_name" {
#   type        = string
#   description = "Name of the target VPC network"
# }

# variable "public_subnet_cidr" {
#   type        = string
#   description = "CIDR block for public resources"
# }

# variable "private_subnet_cidr" {
#   type        = string
#   description = "Primary CIDR block for private compute nodes"
# }

# variable "pods_cidr" {
#   type        = string
#   description = "Secondary IP range CIDR allocation for cluster pods"
# }

# variable "services_cidr" {
#   type        = string
#   description = "Secondary IP range CIDR allocation for cluster services"
# }

variable "project_id" {
  type        = string
  description = "The target Google Cloud Project ID."
}

variable "region" {
  type        = string
  description = "GCP regional location for subnetworks and network routing topology."
}

variable "network_name" {
  type        = string
  description = "The target name configuration string assigned for the VPC network."
}

variable "subnet_name" {
  type        = string
  description = "The primary identity string assigned to the subnetwork instance."
}