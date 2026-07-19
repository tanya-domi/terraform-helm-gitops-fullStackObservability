# ==============================================================================
# Core Deployment Coordinates
# ==============================================================================
project_id          = "project-1cdbea51-6334-4e02-967"
env                 = "dev"
region              = "us-central1"
zone                = "us-central1-a"
cluster_name        = "boutique-gke-cluster"
bucket              = "tanya-terraform-state"
vpc_name            = "boutique-vpc"
subnet_cidr         = "10.0.0.0/20"
pods_cidr           = "10.48.0.0/14"
services_cidr       = "10.52.0.0/20"
public_subnet1_cidr = "10.0.16.0/24" # Changed from "" to a valid placeholder CIDR

# ==============================================================================
# Automated Workload Identities (Short Prefix Names Only)
# ==============================================================================
build_ci_sa_name   = "sa-build-ci"
promote_ci_sa_name = "sa-promote-ci"

# ==============================================================================
# Edge Architecture & Global Routing Topology
# ==============================================================================
dns_zone_name = "tanyadominicsheytech-eu"
dns_domain    = "tanyadominicsheytech.eu."
cert_map_name = "boutique-ingress-cert-map"

# ==============================================================================
# Control Plane Security Access Control
# ==============================================================================
master_authorized_networks = [
  { cidr_block = "79.224.170.140/32", display_name = "wsl-local-machine" },
  { cidr_block = "203.0.113.11/32", display_name = "home-old" },
]
