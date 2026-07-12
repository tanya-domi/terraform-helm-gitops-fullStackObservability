variable "project_id" { type = string }
variable "env" { type = string }
variable "region" { type = string }
variable "repositories" { type = list(string) }
variable "github_pusher_email" { type = string }