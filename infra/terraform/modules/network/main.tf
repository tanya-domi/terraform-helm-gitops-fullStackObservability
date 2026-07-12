resource "google_compute_network" "main" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
}

# Public Subnet (For Load Balancers/Ingress Gateways)
resource "google_compute_subnetwork" "public" {
  name          = "${var.env}-public-subnet"
  ip_cidr_range = var.public_subnet_cidr
  region        = var.region
  network       = google_compute_network.main.id
}

# Private Subnet (For GKE & Managed Internal Services)
resource "google_compute_subnetwork" "private" {
  name                     = "${var.env}-private-subnet"
  ip_cidr_range            = var.private_subnet_cidr
  region                   = var.region
  network                  = google_compute_network.main.id
  private_ip_google_access = true

  secondary_ip_range {
    range_name    = "gke-pods"
    ip_cidr_range = var.pods_cidr
  }
  secondary_ip_range {
    range_name    = "gke-services"
    ip_cidr_range = var.services_cidr
  }
}

# Cloud Router for NAT Control Plane
resource "google_compute_router" "router" {
  name    = "${var.env}-nat-router"
  region  = var.region
  network = google_compute_network.main.id

  bgp {
    asn = 64514
  }
}

# Cloud NAT Gateway for Secured Private Egress
resource "google_compute_router_nat" "nat" {
  name                               = "${var.env}-nat-gateway"
  router                             = google_compute_router.router.name
  region                             = google_compute_router.router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}