
# module "ecr_backend" {
#   source = "../../modules/ecr"

#   repository_name = "${var.env}-${var.project}-backend"
#   github_repo     = var.github_repo

# }


# module "ecr_frontend" {
#   source = "../../modules/ecr"

#   repository_name = "${var.env}-${var.project}-frontend"
#   github_repo     = var.github_repo

# }

locals {
  environments = ["dev", "stg", "prod"]
  services     = ["backend", "frontend"]
}

module "ecr" {
  source   = "../../modules/ecr"
  for_each = { for pair in setproduct(local.environments, local.services) :
    "${pair[0]}-${pair[1]}" => {
      env     = pair[0]
      service = pair[1]
    }
  }

  repository_name = "${each.value.env}-${var.project}-${each.value.service}"
  github_repo     = var.github_repo
}