output "ecr_backend_url" {
  value       = module.ecr_backend.repository_url
  description = "ECR repository URL for backend"
}

output "ecr_backend_name" {
  value       = module.ecr_backend.repository_name
  description = "ECR repository name for backend"
}

output "ecr_backend_role_arn" {
  value       = module.ecr_backend.github_role_arn
  description = "IAM role ARN for backend GitHub Actions"
}

output "ecr_frontend_url" {
  value       = module.ecr_frontend.repository_url
  description = "ECR repository URL for frontend"
}

output "ecr_frontend_name" {
  value       = module.ecr_frontend.repository_name
  description = "ECR repository name for frontend"
}

output "ecr_frontend_role_arn" {
  value       = module.ecr_frontend.github_role_arn
  description = "IAM role ARN for frontend GitHub Actions"
}