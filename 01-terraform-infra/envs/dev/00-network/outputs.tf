output "vpc_id" {
  value       = module.vpc.vpc_id 
  description = "ID głównego VPC dla środowiska DEV"
}

output "vpc_private_subnets" {
  value       = module.vpc.private_subnets
  description = "ID prywatnych podsieci dla środowiska DEV"
}

