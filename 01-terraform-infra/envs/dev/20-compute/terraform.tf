provider "aws" {
  region = "eu-central-1"

  default_tags {
    tags = {
      Environment = var.env
      Terraform   = "true"
      Project     = var.project
    }
  }
}

terraform {
  required_version = ">= 1.13.0"
  
  cloud {
    organization = "k-napiontek"

    workspaces {
      name = "3-Tier-Architecture-dev-compute"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
