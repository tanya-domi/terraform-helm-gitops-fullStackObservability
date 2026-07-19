resource "google_artifact_registry_repository" "my_repos" {
  for_each = toset(var.docker_registries)

  project       = var.project_id
  location      = var.region
  repository_id = "${var.environment}-${each.value}"
  description   = "Managed by Terraform - OCI registry for ${each.value} (${var.environment})"
  format        = "DOCKER"

  cleanup_policies {
    id     = "keep-latest-30"
    action = "KEEP"
    most_recent_versions {
      keep_count = var.cleanup_keep_count
    }
  }

  cleanup_policies {
    id     = "delete-old-artifacts"
    action = "DELETE"
    condition {
      older_than = var.cleanup_older_than
    }
  }
}

# Grant secure write access rights downstream to your GitHub actions pusher account
resource "google_artifact_registry_repository_iam_member" "pusher_access" {
  for_each = var.github_pusher_email != null ? google_artifact_registry_repository.my_repos : {}

  project    = var.project_id
  location   = var.region
  repository = each.value.repository_id # FIX: Reference short id instead of long resource name string
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${var.github_pusher_email}"
}