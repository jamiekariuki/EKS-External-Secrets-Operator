/* output "oidc_provider_arn" {
  description = "OIDC provider ARN"
  value       = module.github-oidc.oidc_provider_arn
} */

output "github_oidc_role" {
  description = "CICD GitHub role."
  value       = module.github-oidc.oidc_role
}