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
  description = "The account ID (short name) for the build CI service account."
}

variable "promote_ci_sa_name" {
  type        = string
  description = "The account ID (short name) for the deployment/promotion CI service account."
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

# ==========================================
# Network Infrastructure Allocations
# ==========================================
variable "vpc_name" {
  type        = string
  description = "Name of the target VPC network."
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

variable "gke_cluster_name" {
  type        = string
  description = "The name of the GKE cluster managed by this loop"
  default     = "telemetry-gke-cluster"
}

