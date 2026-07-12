output "crypto_key_id" {
  description = "The fully qualified cryptographic resource resource path used by storage layers."
  value       = google_kms_crypto_key.key.id
}