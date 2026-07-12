resource "google_kms_key_ring" "ring" {
  project  = var.project_id
  name     = "${var.env}-${var.key_ring_name}"
  location = var.region
}

resource "google_kms_crypto_key" "key" {
  name     = "${var.env}-${var.crypto_key_name}"
  key_ring = google_kms_key_ring.ring.id

  # 90 days rotation schedule meeting strict compliance standards
  rotation_period = "7776000s"

  purpose = "ENCRYPT_DECRYPT"

  lifecycle {
    prevent_destroy = false # Set to true in prod workspaces to safeguard state
  }
}

# Bind cryptographer roles natively to workload identities that need encryption/decryption power
resource "google_kms_crypto_key_iam_member" "gke_disk_encryption" {
  count         = var.gke_service_account_email != "" ? 1 : 0
  crypto_key_id = google_kms_crypto_key.key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${var.gke_service_account_email}"
}


# Retrieve the Google-managed Storage service account for your project
data "google_storage_project_service_account" "gcs_account" {
  project = var.project_id
}

resource "google_kms_crypto_key_iam_member" "gcs_kms_binding" {
  crypto_key_id = google_kms_crypto_key.key.id 
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${var.gke_service_account_email}"
}


# Grant that explicit GCS service account full encryption access to your key
resource "google_kms_crypto_key_iam_member" "gcs_cmek_binding" {
  crypto_key_id = google_kms_crypto_key.key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}"
}