output "repository_urls" {
  description = "The full URLs to the Docker registries"
  value = {
    for k, v in google_artifact_registry_repository.registry : k => "${v.location}-docker.pkg.dev/${var.project_id}/${v.repository_id}"
  }
}