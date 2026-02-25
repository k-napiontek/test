variable "env" {
  type = string
}

variable "eks_cluster_name" {
  type = string
}

variable "argocd_values_file_path" {
  type = string
}

variable "root_infra_yaml_path" {
  type = string
}

variable "root_apps_yaml_path" {
  type = string
}

variable "eks_cluster_endpoint" {
  type        = string
  description = "Endpoint API klastra EKS"
}

variable "eks_cluster_certificate_authority_data" {
  type        = string
  description = "Certyfikat CA klastra w formacie base64"
}