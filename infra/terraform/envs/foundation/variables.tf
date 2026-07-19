# ==========================================
# Core Deployment Coordinates
# ==========================================
variable "project_id" {
  type        = string
  description = "The target Google Cloud Project ID."
}

variable "env" {
  type        = string
  description = "Target deployment environment (e.g., dev, stage, prod)."
}

variable "region" {
  type        = string
  description = "GCP region for subnets and regional resource deployments."
}

variable "zone" {
  type        = string
  description = "The primary compute availability zone."
}

# ==========================================
# Automated Workload Identities (CI/CD)
# ==========================================

variable "build_ci_sa_name" {
  type        = string
  description = "The account ID prefix string for the build CI service account."
}

variable "promote_ci_sa_name" {
  type        = string
  description = "The account ID prefix string for the promotional deployment CI service account."
}

# ==========================================
# Global Ingress & Domain Routing
# ==========================================
variable "dns_zone_name" {
  type        = string
  description = "The target cloud DNS zone resource name matching GCP records."
}

variable "dns_domain" {
  type        = string
  description = "The fully qualified domain name ending with a trailing dot (e.g., boutique.example.com.)."
}

variable "cert_map_name" {
  type        = string
  description = "Target Certificate Manager Map name resource."
}

# ==========================================
# Network Infrastructure Allocations
# ==========================================
variable "vpc_name" {
  type        = string
  description = "Name of the target VPC network."
}

variable "sa-gke-nodes" {
  type        = string
  description = "The account ID prefix string for GKE worker nodes."
}

variable "subnet_cidr" {
  type        = string
  description = "Primary CIDR block for internal GKE nodes and resources."
}

variable "pods_cidr" {
  type        = string
  description = "Secondary IP allocation CIDR block for GKE pods."
}

variable "services_cidr" {
  type        = string
  description = "Secondary IP allocation CIDR block for GKE services."
}

variable "public_subnet1_cidr" {
  type        = string
  description = "CIDR block for public facing resources and ingress proxies."
}

variable "cluster_name" {
  type        = string
  description = "The name of the GKE cluster managed by this loop"
  default     = "telemetry-gke-cluster"
}

variable "master_authorized_networks" {
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default     = []
  description = "External networks permitted access to the GKE control plane API endpoint."
}

variable "bucket" { 
  type        = string 
  description = "GCS bucket for state management."
}

variable "github_repos" {
  type    = list(string)
  default = ["tanya-domi/terraform-helm-gitops-fullStackObservability"]
}

variable "docker_registries" {
  type    = list(string)
  default = ["app-images", "helm-charts"]
}