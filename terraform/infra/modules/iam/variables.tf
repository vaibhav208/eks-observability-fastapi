variable "project_name" { type = string }

variable "github_oidc_provider_arn" {
  description = "OIDC provider ARN for GitHub Actions"
  type        = string
}
