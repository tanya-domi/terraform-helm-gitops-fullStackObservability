output "attestor_name" {
  description = "The name identifier of the initialized secure validator"
  value       = google_binary_authorization_attestor.cosign.name
}