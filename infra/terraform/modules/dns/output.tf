output "zone_name" {
  value       = google_dns_managed_zone.public_zone.name
  description = "The normalized alphanumeric identifier of the public DNS zone resource."
}

output "name_servers" {
  value       = google_dns_managed_zone.public_zone.name_servers
  description = "The authoritative nameserver list to bind at your root domain registrar."
}