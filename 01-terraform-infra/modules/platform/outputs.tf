output "alb_controller_role_arn" {
  value = module.alb_controller.alb_controller_role_arn
}

output "zone_id" {
  value = module.dns.zone_id
}

output "name_servers" {
  value = module.dns.name_servers
}

output "certificate_arn" {
  value = module.dns.certificate_arn
}

output "external_dns_role_arn" {
  value = aws_iam_role.external_dns.arn
}

output "argocd_namespace" {
  value = helm_release.argocd.namespace
}