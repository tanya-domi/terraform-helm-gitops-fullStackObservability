# variable "project_id" {
#   type        = string
#   description = "The target GCP Project ID."
# }

# variable "env" {
#   type        = string
#   description = "Deployment environment (e.g., dev, prod)."
# }

# variable "zone" {
#   type        = string
#   description = "The specific GCP zone to host the GKE control plane."
# }

# variable "cluster_name" {
#   type        = string
#   description = "The baseline name for your GKE compute engine cluster."
# }

# variable "network_id" {
#   type        = string
#   description = "The self_link or ID of the host VPC network."
# }

# variable "subnet_id" {
#   type        = string
#   description = "The self_link or ID of the target private subnetwork."
# }

# variable "node_service_account_email" {
#   type        = string
#   description = "The service account email attached to the GKE worker nodes."
# }

# # ==============================================================================
# # Variables with Safe Production Defaults
# # ==============================================================================

# variable "master_ipv4_cidr_block" {
#   type        = string
#   default     = "172.16.0.0/28"
#   description = "The private IP range in CIDR notation for the GKE master control plane."
# }

# variable "app_node_count" {
#   type        = number
#   default     = 2
#   description = "The number of worker nodes per zone in the application pool."
# }

# variable "app_machine_type" {
#   type        = string
#   default     = "e2-standard-2"
#   description = "The compute instance machine size for runtime microservices."
# }

# variable "monitor_node_count" {
#   type        = number
#   default     = 2
#   description = "The number of worker nodes per zone in the monitoring pool."
# }

# variable "monitor_machine_type" {
#   type        = string
#   default     = "e2-standard-4"
#   description = "The compute instance machine size for memory-intensive observability stacks."
# }


variable "project_id" {
  type        = string
  description = "The target Google Cloud Project ID."
}

variable "region" {
  type        = string
  description = "GCP regional anchor for high-availability node orchestration."
}

variable "env" {
  type        = string
  description = "Target deployment environment lifecycle (e.g., dev, stage, prod)."
}

variable "cluster_name" {
  type        = string
  description = "The target structural name of the GKE compute engine cluster."
}

variable "network" {
  type        = string
  description = "The target VPC name reference string."
}

variable "subnetwork" {
  type        = string
  description = "The subnetwork name reference string."
}

variable "pods_range_name" {
  type        = string
  description = "The secondary IP allocation range name assigned for Pod assets."
}

variable "services_range_name" {
  type        = string
  description = "The secondary IP allocation range name assigned for K8s Service mappings."
}

variable "master_authorized_networks" {
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  description = "External IPv4 CIDR blocks authorized to reach the private control plane endpoint."
  default     = []
}

variable "kms_key_id" {
  type        = string
  description = "The resource identifier for the KMS customer-managed key used to encrypt the etcd database layer."
}

# Node pool size defaults configuration properties
variable "app_node_count" {
  type    = number
  default = 2
}

variable "app_machine_type" {
  type    = string
  default = "e2-standard-4"
}

variable "monitor_node_count" {
  type    = number
  default = 1
}

variable "monitor_machine_type" {
  type    = string
  default = "e2-standard-4"
}