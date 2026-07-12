terraform {
  required_version = ">= 1.6.0"

  backend "gcs" {
    bucket = "tanya-terraform-state"
    prefix = "global/observability/terraform.tfstate"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}