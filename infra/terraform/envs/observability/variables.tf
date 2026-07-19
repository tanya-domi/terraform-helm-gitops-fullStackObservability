variable "project_id" {
  type        = string
  description = "The target GCP Project ID."
}

variable "region" {
  type        = string
  default     = "us-central1"
  description = "The target GCP region where GKE and network layers are deployed."
}

variable "cluster_name" {
  type        = string
  default     = "dev-online-boutique-cluster"
  description = "Name of the target GKE cluster to monitor."
}

variable "notification_email" {
  type        = string
  description = "The baseline email destination for pager notifications."
}

variable "slack_webhook_url" {
  type        = string
  default     = ""
  sensitive   = true
  description = "Optional Slack incoming webhook URL for alert routing."
}

variable "uptime_hosts" {
  type        = list(string)
  description = "List of external ingress hostnames to target for Synthetic Uptime checks."
}

variable "frontend_slo_goal" {
  type        = number
  default     = 0.999
  description = "Target Service Level Objective (SLO) availability decimal (e.g. 0.999 for 99.9%)."
}

variable "runbook_base_url" {
  type        = string
  default     = "https://github.com/tanya-domi/terraform-helm-gitops-fullStackObservability/blob/main/docs/sre/runbooks"
  description = "The root URL matching your repository directory path for debugging runbooks."
}

