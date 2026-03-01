# ---------------------------------------------------------------
# ALB Controller — IAM role + Pod Identity association
# ---------------------------------------------------------------
module "alb_controller" {
  source = "../alb-controller"

  env          = var.env
  cluster_name = var.cluster_name
}

# ---------------------------------------------------------------
# Route53 hosted zone + ACM wildcard certificate
# ---------------------------------------------------------------
module "dns" {
  source = "../route53"

  domain_root = var.domain_root
  tags        = var.tags
}

# ---------------------------------------------------------------
# ExternalDNS — IAM role + Pod Identity
# ---------------------------------------------------------------
resource "aws_iam_role" "external_dns" {
  name = "${var.env}-external-dns"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "pods.eks.amazonaws.com" }
      Action    = ["sts:AssumeRole", "sts:TagSession"]
    }]
  })

  tags = var.tags
}

resource "aws_iam_policy" "external_dns" {
  name = "${var.env}-external-dns-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["route53:ChangeResourceRecordSets"]
        Resource = ["arn:aws:route53:::hostedzone/${module.dns.zone_id}"]
      },
      {
        Effect   = "Allow"
        Action   = ["route53:ListHostedZones", "route53:ListResourceRecordSets"]
        Resource = ["*"]
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "external_dns" {
  role       = aws_iam_role.external_dns.name
  policy_arn = aws_iam_policy.external_dns.arn
}

resource "aws_eks_pod_identity_association" "external_dns" {
  cluster_name    = var.cluster_name
  namespace       = "kube-system"
  service_account = "external-dns-sa"
  role_arn        = aws_iam_role.external_dns.arn
}

# ---------------------------------------------------------------
# ArgoCD — Helm release + app-of-apps root manifests
# ---------------------------------------------------------------
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = "9.4.4"

  values = [file(var.argocd_values_path)]
}

resource "kubectl_manifest" "root_infra" {
  yaml_body = file(var.root_infra_yaml_path)

  depends_on = [helm_release.argocd]
}

resource "kubectl_manifest" "root_apps" {
  yaml_body = file(var.root_apps_yaml_path)

  depends_on = [helm_release.argocd, kubectl_manifest.root_infra]
}
