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

# Production Deployment ProcedureTo handle this cleanly without configuration fragmentation, execute this precise workflow:1.Comment Out GCS Backend:Initial Local State Mode.Temporarily comment out the backend "gcs" block in versions.tf to force Terraform to track resources locally during the first provisioning run.Terraformterraform {
#   required_version = ">= 1.6.0"

#   # Commented out for the initial bootstrap apply
#   # backend "gcs" {
#   #   bucket = "tanya-terraform-state"
#   #   prefix = "bootstrap"
#   # }

#   required_providers {
#     google = { ... }
#   }
# }
# 2.Initialize and Provision Resources:Imperative Setup Run.Run standard initialization and target deployment. This will provision your state bucket, your 3 segregated IAM personas, the OIDC federation providers, and inject the secrets directly into your GitHub repos.Bashterraform init
# terraform apply -var="bucket=tanya-terraform-state"

# 3.Uncomment GCS Backend:Enable Remote State Tracking.
# Uncomment the backend "gcs" block in versions.tf. Ensure the bucket attribute matches the name of the bucket that was just created during Step 2.

# 4.Execute State Migration:Migrate Local -.GCS">Run terraform init again. 

# Terraform will detect that you've added a remote backend configuration and will prompt you to migrate your existing local state file into the cloud bucket.
# terraform init -migrate-state
# Type yes when prompted. Your local .tfstate files can now be safely deleted or ignored, as tracking has successfully moved to the secure cloud.

# Finalized versions.tf (Post-Migration Structure)Terraformterraform {
#   required_version = ">= 1.6.0"

#   # Active GCS Remote Backend Configuration
#   backend "gcs" {
#     bucket = "tanya-terraform-state"
#     prefix = "bootstrap/state" # Added path clarity
#   }

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