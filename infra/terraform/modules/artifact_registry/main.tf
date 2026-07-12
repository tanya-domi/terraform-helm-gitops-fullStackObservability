resource "google_artifact_registry_repository" "registry" {
  for_each = toset(var.repositories)

  project       = var.project_id
  location      = var.region
  repository_id = "${var.env}-${each.key}"
  description   = "Managed secure store container tracking ${each.key} packages for ${var.env}"
  format        = "DOCKER"

  docker_config {
    immutable_tags = false
  }

  # Policy 1: Protect current deployment iterations from sweeping deletion
  cleanup_policies {
    id     = "keep-latest-30"
    action = "KEEP"
    most_recent_versions {
      keep_count = 30
    }
  }

  # Policy 2: Automatically purge untagged or old historical layers
  cleanup_policies {
    id     = "delete-old-images"
    action = "DELETE"
    condition {
      older_than = "7776000s" # 90 days explicitly
    }
  }
}

# Grant secure write access rights downstream to your GitHub actions pusher account
resource "google_artifact_registry_repository_iam_member" "pusher_access" {
  for_each = google_artifact_registry_repository.registry

  project    = var.project_id
  location   = var.region
  repository = each.value.name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${var.github_pusher_email}"
}