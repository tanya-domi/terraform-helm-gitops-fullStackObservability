terraform {
  required_version = ">= 1.6.0"

# Remote Backend  for Bootstrap
  backend "gcs" {
    bucket = "tanya-terraform-state"
    prefix = "bootstrap"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}


