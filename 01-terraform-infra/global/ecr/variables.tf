variable "env" {
  type = string
}

variable "project" {
  type    = string
  default = "myapp"
}

variable "github_repo" {
  type        = string
  description = "GitHub repository in format owner/repo (e.g. myorg/my-project)"
}
