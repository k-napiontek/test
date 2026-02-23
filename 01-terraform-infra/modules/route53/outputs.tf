
output "zone_id" {
  value = aws_route53_zone.main.zone_id
}

output "name_servers" {
  value = aws_route53_zone.main.name_servers
}
output "external_dns_role_arn" {
  value = aws_iam_role.external_dns.arn
}