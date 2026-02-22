output "ecr_repositories" {
  value = {
    for key, mod in module.ecr : key => {
      url      = mod.repository_url
      name     = mod.repository_name
      arn      = mod.repository_arn
      role_arn = mod.github_role_arn
    }
  }
  description = "Map of all ECR repositories (key format: env-service, e.g. dev-backend)"
}