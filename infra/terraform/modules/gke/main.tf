

# ==============================================================================
# Cost-Optimized Zonal GKE Control Plane (Single Availability Zone)
# ==============================================================================
resource "google_container_cluster" "primary" {
  project             = var.project_id
  name                = var.cluster_name
  location            = "${var.region}-a" # Appends active zone (e.g., us-central1-a) to bypass regional charges
  deletion_protection = false

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  network    = var.network
  subnetwork = var.subnetwork

  remove_default_node_pool = true
  initial_node_count       = 1
  
  networking_mode = "VPC_NATIVE"
  ip_allocation_policy {
    cluster_secondary_range_name  = var.pods_range_name
    services_secondary_range_name = var.services_range_name
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false 
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  master_authorized_networks_config {
    dynamic "cidr_blocks" {
      for_each = var.master_authorized_networks
      content {
        cidr_block   = cidr_blocks.value.cidr_block
        display_name = cidr_blocks.value.display_name
      }
    }
  }

  database_encryption {
    state    = "ENCRYPTED"
    key_name = var.kms_key_id
  }

  secret_manager_config {
    enabled = true
  }

  logging_config {
    enable_components = []
  }
  monitoring_config {
    enable_components = []
  }
}

# ==============================================================================
# Dedicated Isolated Node Pools 
# ==============================================================================
resource "google_container_node_pool" "app_nodes" {
  project    = var.project_id
  name       = "application-pool"
  cluster    = google_container_cluster.primary.id
  location   = google_container_cluster.primary.location
  node_count = 2 
  
  node_config {
    machine_type = "e2-standard-2"
    disk_size_gb = 50
    disk_type    = "pd-balanced"
    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
    
    workload_metadata_config { 
      mode = "GKE_METADATA" 
    }
    
    labels = { 
      role = "application" 
    }
  }
}

resource "google_container_node_pool" "monitor_nodes" {
  project    = var.project_id
  name       = "monitoring-pool"
  cluster    = google_container_cluster.primary.id
  location   = google_container_cluster.primary.location
  node_count = 2 # 2 total VMs dedicated to Thanos, Tempo, Prom, Grafana

  node_config {
    machine_type = "e2-standard-4" # Heavier compute slice for local observability engines
    disk_size_gb = 50
    disk_type    = "pd-balanced"
    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
    
    workload_metadata_config { 
      mode = "GKE_METADATA" 
    }
    
    labels = { 
      role = "monitoring" 
    }
    
    taint {
      key    = "dedicated"
      value  = "monitoring"
      effect = "NO_SCHEDULE"
    }
  }
}

