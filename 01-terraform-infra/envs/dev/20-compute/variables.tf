variable "env" {
  type = string
}

variable "project" {
  type = string
}

variable "node_instance_types" {
  type = list(string)
}

variable "node_desired_size" {
  type = number
}

variable "node_min_size" {
  type = number
}

variable "node_max_size" {
  type = number
}

variable "kubernetes_version" {
  type = string
}

variable "cluster_endpoint_public_access" {
  type    = bool
  default = true
}

variable "cluster_endpoint_public_access_cidrs" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "cloudwatch_log_retention_days" {
  type    = number
  default = 30
}
variable "cluster_name" {
  type = string
}

