output "vpc_id" {
  value       = module.vpc.vpc_id 
  description = "ID głównego VPC dla środowiska DEV"
}