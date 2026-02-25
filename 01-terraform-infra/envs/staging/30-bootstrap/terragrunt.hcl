include "root" {
  path = find_in_parent_folders("terragrunt.hcl")
}

terraform {
  source = "${get_repo_root()}/01-terraform-infra//layers/30-bootstrap"
}

dependency "compute" {
  config_path = "../20-compute"

  mock_outputs = {
    eks_cluster_name                      = "mock-cluster"
    eks_cluster_endpoint                  = "https://mock.eks.amazonaws.com"
    // eks_cluster_certificate_authority_data = "bW9jaw=="
    eks_cluster_certificate_authority_data = "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUNXRENDQWNLZ0F3SUJBZ0lCQVRBTkJna3Foa2lHOXcwQkFRVUZBREFsTVFzd0NRWURWUVFHRXdKUVRERVcKTUJRR0ExVUVBeE1OYlc5amF5MWpaWEowTG1sdWREQWVGdzB5TURBeE1ERXdNREF3TURCYUZ3MHpNREF4TURFdwpNREF3TURCYU1DVXhDekFKQmdOVkJBWVRBbFJNTVJZd0ZBWURWUVFERXcxMWIyTnJMV05sY25RdWFXNTBNSUdmCk1BMEdDU3FHU0liM0RRRUJBUVVBQTRHTkFEQ0JpUUtCZ1QCclhiNUsvei8rMEVPRjdQMkh1R3YvY01IUGsveUcKbkh5UjBReDBxTHU5bXk2aTBnVW5wL0tUeGlGMEE3S05hWHNidS90RndyRGJWMWk2RExOQStJOWRxb0h1THM2dApzWlp1d0ZzZTB1L2lHTlIraEd4MnhRZEg0bC9tSU82TllLQUw3SU55L0tLZEJndkVtUVRsMEhyTlhjU1A3clJhClR4bmlRbm5oSkx2OWNRSURBUUFCTUEwR0NTcUdTSWIzRFFFQkJRVUFBNEdCQUFzUE9WSTVUd0lPZGkzKzNidTEKNlBNVTRoRmFzU2J5L2tnd1hOQVdOVzVHRm5wV04zdkt0NUNVNDlEMWlscTFnR3I2YmRxRzZMVU5LTDJ6MUlqVQp5S3d4RjB6THVqdkN6RG1kM3p6a0NmbUo4akwva2E3dWNDbjdBcjBCWStTTHh6NW9hS01IbmN1c1p3QUVVMUZjCmQraVV4Q0toZklJbjZabE1pWUp1aTBvcQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg=="
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

inputs = {
  env                     = local.env_vars.locals.env
  eks_cluster_name        = dependency.compute.outputs.eks_cluster_name
  eks_cluster_endpoint                   = dependency.compute.outputs.eks_cluster_endpoint
  eks_cluster_certificate_authority_data = dependency.compute.outputs.eks_cluster_certificate_authority_data

  argocd_values_file_path = "${abspath(get_terragrunt_dir())}/argocd-values.yaml"
  root_infra_yaml_path    = "${abspath(get_repo_root())}/03-gitops-infra/root-infra.yaml"
  root_apps_yaml_path     = "${abspath(get_repo_root())}/04-gitops-apps/staging-appset.yaml"
}