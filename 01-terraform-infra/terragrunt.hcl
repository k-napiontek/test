locals {
  env_vars    = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  common_vars = read_terragrunt_config(find_in_parent_folders("_env.hcl"))

  env     = local.env_vars.locals.env
  project = local.common_vars.locals.project
  layer   = basename(get_terragrunt_dir())
}
terraform_binary = "tofu"
generate "backend" {
  path      = "backend_generated.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    terraform {
      required_version = ">= 1.11.0"

      backend "s3" {
        bucket       = "k-napiontek-terraform-state1"
        key          = "${local.env}/${local.layer}/terraform.tfstate"
        region       = "eu-central-1"
        encrypt      = true
        use_lockfile = true
      }
    }
  EOF
}

generate "provider" {
  path      = "provider_generated.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    provider "aws" {
      region = "eu-central-1"

      default_tags {
        tags = {
          Environment = "${local.env}"
          Terraform   = "true"
          Project     = "${local.project}"
        }
      }
    }
  EOF
}