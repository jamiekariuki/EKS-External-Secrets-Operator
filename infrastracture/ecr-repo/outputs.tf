

output "frontend_repository_url" {
  value = module.ecr_frontend.repository_url
}

output "backend_repository_url" {
  value = module.ecr_backend.repository_url
}
