module "argocd" {
  source = "../../modules/argocd"

  values_file_path     = var.argocd_values_file_path
  eks_cluster_name     = var.eks_cluster_name
  root_infra_yaml_path = var.root_infra_yaml_path
  root_apps_yaml_path  = var.root_apps_yaml_path
}

module "alb" {
  source = "../../modules/alb"

  env          = var.env
  cluster_name = var.eks_cluster_name
}

module "route53" {
  source = "../../modules/route53"

  env          = var.env
  cluster_name = var.eks_cluster_name
}