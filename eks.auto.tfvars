# general 
customer = "mustafa"
env      = "prod"

# vpc
vpc_cidr_block = "10.40.0.0/16"
# vpc_availability_zones = ["us-east-1a"]
vpc_public_subnets  = ["10.40.1.0/24","10.40.2.0/24"]
vpc_private_subnets = ["10.40.32.0/24"]



# EC2 variables values
ssh_ec2_keypair = "ssh-keypair"



# EKS Cluster Name
eks_cluster_name = "eks-demo"
eks_ipv4_cidr_range = "172.20.0.0/16"
eks_cluster_version = "1.24"
eks_cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]
