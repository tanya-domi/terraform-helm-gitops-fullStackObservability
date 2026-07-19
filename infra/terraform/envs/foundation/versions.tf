terraform {
  required_version = ">= 1.6.0"

  # Remote GCS Backend  for C Infrastructure Layer
  backend "gcs" {
    bucket = "tanya-terraform-state"
    prefix = "foundation" # Isolates state file
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.14"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.31"
    }
  }
}





