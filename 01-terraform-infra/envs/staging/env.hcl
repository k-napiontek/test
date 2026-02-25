locals {
  env          = "stg"
  cluster_name = "k8s-crypto-stg1"

  # 00-network
  vpc_cidr             = "10.1.0.0/16"
  private_subnet_cidrs = ["10.1.1.0/24", "10.1.2.0/24"]
  public_subnet_cidrs  = ["10.1.101.0/24", "10.1.102.0/24"]
  single_nat_gateway   = true

  # 20-compute
  kubernetes_version                   = "1.34"
  cluster_endpoint_public_access       = true
  cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]
  cloudwatch_log_retention_days        = 30
  node_instance_types                  = ["c7i-flex.large"]
  node_desired_size                    = 2
  node_min_size                        = 2
  node_max_size                        = 6

  # 30-bootstrap
  root_infra_yaml_path    = "${get_repo_root()}/03-gitops-infra/root-infra.yaml"
  root_apps_yaml_path     = "${get_repo_root()}/04-gitops-apps/staging-appset.yaml"
}