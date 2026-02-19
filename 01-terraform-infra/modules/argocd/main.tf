

module "argocd_image_updater_pod_identity" {
  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 2.7" # Pinned to the latest 2.x series

  name = "argocd-image-updater-role"

  # Corrected for v2.7+: Uses `additional_policy_arns` and a map {} instead of a list []
  additional_policy_arns = {
    ecr_read_only = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  }

  associations = {
    image_updater = {
      cluster_name    = var.eks_cluster_name # Pass this from your compute layer
      namespace       = "argocd"
      service_account = "argocd-image-updater"
    }
  }
}



resource "aws_secretsmanager_secret" "argocd_git_creds" {
  name        = "dev/argocd/git-credentials"
  description = "GitHub/GitLab credentials for ArgoCD"
}

resource "aws_secretsmanager_secret_version" "argocd_git_creds_val" {
  secret_id     = aws_secretsmanager_secret.argocd_git_creds.id
  secret_string = jsonencode({
    username = "git-user"
    password = "CHANGE_ME"
  })
  
  lifecycle {
    ignore_changes = [secret_string]
  }
}


resource "helm_release" "argocd" {
  name = "my-argo-cd"
  repository = "https://argoproj.github.io/argo-helm"
  chart = "argo-cd"
  namespace = "argocd"
  create_namespace = true
  version = "9.4.0"

  values = [
    file(var.values_file_path)
  ]
}

resource "kubectl_manifest" "root_infra" {
  yaml_body = file("${path.module}/../../../03-gitops-infra/root-infra.yaml")

  depends_on = [ helm_release.argocd ]
}

resource "kubectl_manifest" "root_apps" {
  yaml_body = file("${path.module}/../../../04-gitops-apps/root-apps.yaml")

  depends_on = [ helm_release.argocd, kubectl_manifest.root_infra ]
}