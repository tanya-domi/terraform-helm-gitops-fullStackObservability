# resource "google_compute_network" "main" {
#   name                    = var.vpc_name
#   auto_create_subnetworks = false
# }

# # Public Subnet (For Load Balancers/Ingress Gateways)
# resource "google_compute_subnetwork" "public" {
#   name          = "${var.env}-public-subnet"
#   ip_cidr_range = var.public_subnet_cidr
#   region        = var.region
#   network       = google_compute_network.main.id
# }

# # Private Subnet (For GKE & Managed Internal Services)
# resource "google_compute_subnetwork" "private" {
#   name                     = "${var.env}-private-subnet"
#   ip_cidr_range            = var.private_subnet_cidr
#   region                   = var.region
#   network                  = google_compute_network.main.id
#   private_ip_google_access = true

#   secondary_ip_range {
#     range_name    = "gke-pods"
#     ip_cidr_range = var.pods_cidr
#   }
#   secondary_ip_range {
#     range_name    = "gke-services"
#     ip_cidr_range = var.services_cidr
#   }
# }

# # Cloud Router for NAT Control Plane
# resource "google_compute_router" "router" {
#   name    = "${var.env}-nat-router"
#   region  = var.region
#   network = google_compute_network.main.id

#   bgp {
#     asn = 64514
#   }
# }

# # Cloud NAT Gateway for Secured Private Egress
# resource "google_compute_router_nat" "nat" {
#   name                               = "${var.env}-nat-gateway"
#   router                             = google_compute_router.router.name
#   region                             = google_compute_router.router.region
#   nat_ip_allocate_option             = "AUTO_ONLY"
#   source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

#   log_config {
#     enable = true
#     filter = "ERRORS_ONLY"
#   }
# }




locals {
  pods_range     = "${var.subnet_name}-pods"
  services_range = "${var.subnet_name}-services"
}

resource "google_compute_network" "vpc" {
  project                 = var.project_id
  name                    = var.network_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "gke" {
  project                  = var.project_id
  name                     = var.subnet_name
  ip_cidr_range            = "10.10.0.0/20"
  region                   = var.region
  network                  = google_compute_network.vpc.id
  private_ip_google_access = true

  secondary_ip_range {
    range_name    = local.pods_range
    ip_cidr_range = "10.20.0.0/16"
  }

  secondary_ip_range {
    range_name    = local.services_range
    ip_cidr_range = "10.30.0.0/20"
  }
}

resource "google_compute_router" "router" {
  project = var.project_id
  name    = "${var.network_name}-router"
  region  = var.region
  network = google_compute_network.vpc.id
}

resource "google_compute_router_nat" "nat" {
  project                            = var.project_id
  name                               = "${var.network_name}-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}