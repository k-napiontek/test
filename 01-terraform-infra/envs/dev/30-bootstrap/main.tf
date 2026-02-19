module "argocd" {
    source = "../../../modules/argocd"


    values_file_path = "${abspath(path.module)}/argocd-values.yaml"

    eks_cluster_name = data.terraform_remote_state.compute.outputs.eks_cluster_name
}