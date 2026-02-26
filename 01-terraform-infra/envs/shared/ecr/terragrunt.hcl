include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_repo_root()}//01-terraform-infra/modules/ecr"
}

inputs = {
  repositories = {
    "myapp/client-service" = {}
    "myapp/basket-service" = {}
    "myapp/auth-service"   = {}
  }

  pull_account_arns = [
    "arn:aws:iam::188494185951:root",
  ]

  github_repo                 = "k-napiontek/cloud-engineering-portfolio"
  create_github_oidc_provider = true
}
