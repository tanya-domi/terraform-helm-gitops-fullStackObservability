# Binary Authorization is a Google Cloud security service designed to ensure that only trusted container images are deployed to GKE
# In an enterprise platform setup, you want to prevent unauthorized or vulnerable images from running in production (e.g., an engineer pulling a malicious image from a public hub or an attacker trying to run unauthorized code).


# Container Analysis Note: Acts as the storage anchor for signatures
resource "google_container_analysis_note" "cosign" {
  project = var.project_id
  name    = "${var.env}-boutique-cosign-note"

  attestation_authority {
    hint {
      human_readable_name = "Cosign Secure Attestation Authority"
    }
  }
}

# The Attestor: The validator that GKE checks against during deployment
resource "google_binary_authorization_attestor" "cosign" {
  project     = var.project_id
  name        = "${var.env}-boutique-cosign-attestor"
  description = "Validates secure container signatures coming from GitHub Actions workflows"

  attestation_authority_note {
    note_reference = google_container_analysis_note.cosign.id # Uses the full structural resource ID
  }
}

# The Cluster Policy Engine
resource "google_binary_authorization_policy" "policy" {
  project = var.project_id

  # Always whitelist public system images to prevent blocking critical K8s controllers
  admission_whitelist_patterns {
    name_pattern = "gcr.io/google-containers/*"
  }
  admission_whitelist_patterns {
    name_pattern = "k8s.gcr.io/*"
  }
  admission_whitelist_patterns {
    name_pattern = "registry.k8s.io/*"
  }

  # Production Guardrail Strategy: Set to DRYRUN first so it prints alerts without dropping containers
  default_admission_rule {
    evaluation_mode  = "ALWAYS_ALLOW" 
    enforcement_mode = "DRYRUN_AUDIT_LOG_ONLY"
  }
}





















# How It Operates in this Architecture:
# The Attestor & Note: Your google_container_analysis_note and attestor create a "metadata lockbox".
# The Signing Phase: When GitHub Actions successfully builds your application microservice and passes security vulnerability scans, it uses a signing tool (like Sigstore Cosign) to digitally sign the image SHA.
# The Deployment Gate: When ArgoCD attempts to deploy that image to GKE, GKE intercepts the request, verifies that the image signature matches your Cloud Attestor, and either blocks or allows the pod based on your rules.