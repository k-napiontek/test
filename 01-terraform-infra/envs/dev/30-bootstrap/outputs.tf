output "alb_controller_role_arn" {
  value       = module.alb.alb_controller_role_arn
}



output "zone_id" {
  value = module.route53.zone_id
}

output "name_servers" {
  value = module.route53.name_servers
}
output "external_dns_role_arn" {
  value = module.route53.external_dns_role_arn
}

output "certificate_arn" {
  value = module.route53.certificate_arn
}