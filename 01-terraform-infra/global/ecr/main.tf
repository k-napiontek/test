
module "ecr_backend" {
  source = "../../modules/ecr"

  repository_name = "${var.env}-${var.project}-backend"
  github_repo     = var.github_repo

}


module "ecr_frontend" {
  source = "../../modules/ecr"

  repository_name = "${var.env}-${var.project}-frontend"
  github_repo     = var.github_repo

}

