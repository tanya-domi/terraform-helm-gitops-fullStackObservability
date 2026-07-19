
# ==============================================================================
# . CERTIFICATE MANAGER & CLOUD DNS RESOURCES
# ==============================================================================

# 1. Orchestrate the DNS ACME Challenge Authorization Hook
resource "google_certificate_manager_dns_authorization" "instance" {
  project     = var.project_id
  name        = "${var.dns_zone_name}-auth"
  description = "ACME challenge verification anchor for ${var.domain}"
  domain      = var.domain
}

# 2. Inject Verification Record cleanly into the corresponding Managed Zone
resource "google_dns_record_set" "cname_challenge" {
  project      = var.project_id
  managed_zone = var.dns_zone_name
  name         = google_certificate_manager_dns_authorization.instance.dns_resource_record[0].name
  type         = google_certificate_manager_dns_authorization.instance.dns_resource_record[0].type
  ttl          = 60
  rrdatas      = [google_certificate_manager_dns_authorization.instance.dns_resource_record[0].data]
}

# 3. Provision the Google-Managed SSL Certificate targeting Let's Encrypt / Google Trust Services
resource "google_certificate_manager_certificate" "managed_cert" {
  project     = var.project_id
  name        = "${var.dns_zone_name}-cert"
  description = "Automated production edge SSL wildcard/naked certificate asset."
  
  managed {
    domains = [
      var.domain,
      "*.${var.domain}"
    ]
    dns_authorizations = [
      google_certificate_manager_dns_authorization.instance.id
    ]
  }

  depends_on = [google_dns_record_set.cname_challenge]
}

# 4. Generate the Ingress Certificate Map Architecture 
resource "google_certificate_manager_certificate_map" "target_map" {
  project     = var.project_id
  name        = var.cert_map_name
  description = "Edge routing mapping for regional gateway proxy terminations."
}

# 5. Bind Primary Cert Instance to Target Map Route
resource "google_certificate_manager_certificate_map_entry" "primary" {
  project      = var.project_id
  name         = "${var.dns_zone_name}-primary-entry"
  map          = google_certificate_manager_certificate_map.target_map.name
  certificates = [google_certificate_manager_certificate.managed_cert.id]
  hostname     = var.domain
}

# 6. Bind Wildcard Entry Variant to Map Route
resource "google_certificate_manager_certificate_map_entry" "wildcard" {
  project      = var.project_id
  name         = "${var.dns_zone_name}-wildcard-entry"
  map          = google_certificate_manager_certificate_map.target_map.name
  certificates = [google_certificate_manager_certificate.managed_cert.id]
  hostname     = "*.${var.domain}"
}