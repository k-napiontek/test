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

provider "helm" {
  kubernetes = {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

provider "kubectl" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
}

terraform {
  required_version = ">= 1.13.0"
  
  cloud {
    organization = "k-napiontek"

    workspaces {
      name = "3-Tier-Architecture-dev-bootstrap"
    }
  }

  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = ">= 6.0"
    }

     helm = {
      source = "hashicorp/helm"
      version = ">= 3.1.1"
    }

    kubectl = {
      source = "alekc/kubectl"
      version = "2.1.3"
    }
    
  }
}
