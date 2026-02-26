variable "env" {
  type = string
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster name (full name as returned by EKS module)"
}

variable "domain_root" {
  type        = string
  description = "Root domain for Route53 zone and ACM cert (e.g. bzyk0945.site)"
}

variable "argocd_values_path" {
  type        = string
  description = "Path to ArgoCD Helm values YAML"
}

variable "root_infra_yaml_path" {
  type        = string
  description = "Path to root-infra Application manifest"
}

variable "root_apps_yaml_path" {
  type        = string
  description = "Path to root-apps ApplicationSet manifest"
}

variable "tags" {
  type    = map(string)
  default = {}
}
