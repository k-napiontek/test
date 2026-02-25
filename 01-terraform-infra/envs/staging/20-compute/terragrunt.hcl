include "root" {
  path = find_in_parent_folders("terragrunt.hcl")
}

terraform {
  source = "${get_repo_root()}/01-terraform-infra//layers/20-compute"
}

dependency "network" {
  config_path = "../00-network"

  mock_outputs = {
    vpc_id              = "vpc-00000000000000000"
    vpc_private_subnets = ["subnet-00000000000000001", "subnet-00000000000000002"]
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

inputs = {
  env          = local.env_vars.locals.env
  cluster_name = local.env_vars.locals.cluster_name
  vpc_id       = dependency.network.outputs.vpc_id
  subnet_ids   = dependency.network.outputs.vpc_private_subnets

  kubernetes_version                   = local.env_vars.locals.kubernetes_version
  cluster_endpoint_public_access       = local.env_vars.locals.cluster_endpoint_public_access
  cluster_endpoint_public_access_cidrs = local.env_vars.locals.cluster_endpoint_public_access_cidrs
  cloudwatch_log_retention_days        = local.env_vars.locals.cloudwatch_log_retention_days
  node_instance_types                  = local.env_vars.locals.node_instance_types
  node_desired_size                    = local.env_vars.locals.node_desired_size
  node_min_size                        = local.env_vars.locals.node_min_size
  node_max_size                        = local.env_vars.locals.node_max_size
}