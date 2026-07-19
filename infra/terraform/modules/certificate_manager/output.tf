# Remove or fix the 'cert_map_name' block that was causing the error
output "certificate_map_id" {
  value       = google_certificate_manager_certificate_map.target_map.id
  description = "The fully qualified structural resource string tracking the certificate mapping configuration."
}

output "certificate_map_name" {
  value       = google_certificate_manager_certificate_map.target_map.name
  description = "The unique identifier name of the Certificate Manager map."
}

# Remove this block entirely as it is a duplicate and was causing the error:
# output "cert_map_name" {
#   value = google_certificate_manager_certificate_map.gateway.name
# }

output "certificate_name" {
  value = google_certificate_manager_certificate.managed_cert.name
}