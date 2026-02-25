# variable "cluster_name" {
#   type        = string
#   description = "EKS cluster name (for IAM role name and Pod Identity association)"
# }

# variable "ecr_repository_arn" {
#   type        = string
#   default     = null
#   description = "ARN of ECR repository for Image Updater (ecr:DescribeImages, ecr:ListImages). If null, only AmazonEC2ContainerRegistryReadOnly is attached."
# }

# variable "app_of_apps_repo_url" {
#   type        = string
#   description = "Git repo URL for the root Application (app-of-apps)"
# }

# variable "app_of_apps_path" {
#   type        = string
#   default     = "argocd/apps"
#   description = "Path in the repo where Application manifests are"
# }

# variable "app_of_apps_target_revision" {
#   type        = string
#   default     = "main"
#   description = "Branch/tag for the app-of-apps repo"
# }

# variable "oidc_provider_arn" {
#   type        = string
#   description = "ARN of the OIDC provider for the EKS cluster"
# }

variable "values_file_path" {
  description = "Absolute or relative path to the values template file"
  type        = string
}

variable "eks_cluster_name" {}

variable "root_infra_yaml_path" {
  type = string
}

variable "root_apps_yaml_path" {
  type = string
}