# Look up the globally managed parent public DNS zone
# data "google_dns_managed_zone" "parent_zone" {
#   name    = var.zone_name
#   project = var.project_id
# }

# # Declaratively stitch the environment subdomain directly to the target Ingress IP
# resource "google_dns_record_set" "ingress_record" {
#   project      = var.project_id
#   managed_zone = data.google_dns_managed_zone.parent_zone.name
  
#   # Becomes dev.tanyadominicsheytech.eu.
#   name    = "${var.subdomain}.${data.google_dns_managed_zone.parent_zone.dns_name}"
#   type    = "A"
#   ttl     = 300
#   rrdatas = [var.target_ip_address]
# }


resource "google_dns_managed_zone" "public_zone" {
  project     = var.project_id
  name        = var.zone_name
  dns_name    = var.dns_name
  description = "Managed edge zone routing traffic for the Online Boutique ecosystem."
  visibility  = "public"

  dnssec_config {
    state = "on"
  }
}