env = "dev"
project = "myapp"

cluster_name = "myapp"
kubernetes_version                   = "1.34"
cluster_endpoint_public_access       = true
cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]
cloudwatch_log_retention_days        = 30

node_instance_types = ["c7i-flex.large"]
node_desired_size   = 2
node_min_size       = 1
node_max_size       = 4