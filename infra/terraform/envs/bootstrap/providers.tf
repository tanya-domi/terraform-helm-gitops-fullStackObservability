# terraform {
#   required_version = ">= 1.8.0"
#   required_providers {
#     google = {
#       source  = "hashicorp/google"
#       version = "~> 6.0"
#     }
#     github = {
#       source  = "integrations/github"
#       version = "~> 6.0"
#     }
#   }
# }

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "github" {
  token = var.github_token
  owner = "tanya-domi"
}