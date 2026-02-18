## WSZEDZE
locals {
  cluster_name = "${var.env}-${var.cluster_name}"


  tags = merge(var.tags, {
    Environment = var.env
    Terraform   = "true"
    Project     = var.project
  })

}
module "ecr" {
  source = "../../modules/ecr"

  repository_name = "${var.env}-${var.project}"
  github_repo     = var.github_repo

  tags = local.tags
}