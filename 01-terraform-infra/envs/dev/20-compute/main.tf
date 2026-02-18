
module "eks" {
  source = "../../modules/eks"

  cluster_name       = local.cluster_name
  kubernetes_version = var.kubernetes_version
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.private_subnets

  cluster_endpoint_public_access       = var.cluster_endpoint_public_access
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs
  cloudwatch_log_retention_days        = var.cloudwatch_log_retention_days

   eks_managed_node_groups = {
    general = {
      instance_types = var.node_instance_types
      min_size       = var.node_min_size
      max_size       = var.node_max_size
      desired_size   = var.node_desired_size
    }
  }

  # vpc-cni i coredns muszą być przed node group (before_compute), żeby węzły miały sieć przy starcie
  addons = {
    vpc-cni = {
      before_compute = true
      most_recent    = true
    }
    coredns = {
      most_recent    = true
    }
    kube-proxy = { most_recent = true }
  }

  tags = local.tags
}