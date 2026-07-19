output "repository_urls" {
  description = "Map of registry names to their full Docker URLs"
  value = {
    for k, v in google_artifact_registry_repository.my_repos : k => "${v.location}-docker.pkg.dev/${var.project_id}/${v.name}"
  }
}

