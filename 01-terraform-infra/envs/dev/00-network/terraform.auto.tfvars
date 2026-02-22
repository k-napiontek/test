project      = "myapp"
env          = "dev"
cluster_name = "k8s-crypto-dev"
vpc_cidr     = "10.0.0.0/16"

# Frankfurt (eu-central-1)
azs = ["eu-central-1a", "eu-central-1b"]

private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
public_subnet_cidrs  = ["10.0.101.0/24", "10.0.102.0/24"]

single_nat_gateway = true