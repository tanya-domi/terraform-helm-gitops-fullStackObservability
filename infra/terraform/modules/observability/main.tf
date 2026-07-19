# ==============================================================================
# 1. Unified Namespaces (Declared First to Prevent Dependency Race Conditions)
# ==============================================================================
resource "kubernetes_namespace_v1" "monitoring" {
  metadata {
    name = "monitoring"
    labels = {
      environment = var.env
      managed-by  = "terraform"
    }
  }
}

resource "kubernetes_namespace_v1" "efk" {
  metadata {
    name = "efk"
    labels = {
      environment = var.env
      managed-by  = "terraform"
    }
  }
}

resource "kubernetes_namespace_v1" "external_secrets" {
  metadata {
    name = "external-secrets"
    labels = {
      environment = var.env
      managed-by  = "terraform"
    }
  }
}

# ==============================================================================
# 2. Secure Long-Term Observability Storage Buckets
# ==============================================================================
locals {
  bucket_names = ["tempo", "thanos", "elasticsearch-archive"]
}

resource "google_storage_bucket" "observability_buckets" {
  for_each      = toset(local.bucket_names)
  project       = var.project_id
  name          = "${var.project_id}-${var.env}-${each.key}-storage"
  location      = var.region
  force_destroy = var.env == "prod" ? false : true

  storage_class               = "STANDARD"
  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type = "Delete"
    }
  }
}