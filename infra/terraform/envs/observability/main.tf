provider "google" {
  project               = var.project_id
  region                = var.region
  user_project_override = true
  billing_project       = var.project_id
}

# Core SRE Monitoring & Alerting Fabric
module "observability" {
  source = "../../modules/observability"

  project_id         = var.project_id
  cluster_name       = var.cluster_name
  cluster_location   = var.region
  notification_email = var.notification_email
  slack_webhook_url  = var.slack_webhook_url
  uptime_hosts       = var.uptime_hosts
  frontend_slo_goal  = var.frontend_slo_goal
  runbook_base_url   = var.runbook_base_url
}