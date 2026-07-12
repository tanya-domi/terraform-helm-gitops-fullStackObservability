output "notification_channel_email" {
  description = "The Cloud Monitoring generated email notification channel resource path."
  value       = module.observability.notification_channel_email
}

output "uptime_check_ids" {
  description = "The list of IDs assigned to synthetic availability checks."
  value       = module.observability.uptime_check_ids
}

output "frontend_slo_id" {
  description = "The unique tracking ID assigned to your Frontend availability SLO."
  value       = module.observability.frontend_slo_id
}

output "dashboard_id" {
  description = "The resource path for the generated SRE Platform Cockpit dashboard."
  value       = module.observability.dashboard_id
}