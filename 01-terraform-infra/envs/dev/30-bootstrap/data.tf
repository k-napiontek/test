data "terraform_remote_state" "compute" {
    backend = "remote"

    config = {
      organization = "k-napiontek"
      workspaces = {
        name = "3-Tier-Architecture-dev-compute"
      }
    }
}

data "aws_eks_cluster" "cluster" {
  name = data.terraform_remote_state.compute.outputs.eks_cluster_name 
}

data "aws_eks_cluster_auth" "cluster" {
  name = data.terraform_remote_state.compute.outputs.eks_cluster_name
}