variable "region" {
  default = "us-east-1"
  type    = string
}

variable "env" {
  default = "dev"
  type    = string
}

variable "customer" {
  default = "curity"
  type    = string
}
variable "vpc_cidr_block" {
  description = "VPC CIDR Block"
  type        = string
}
/*
variable "vpc_availability_zones" {
  description = "VPC Availability Zones"
  type        = list(string)
}*/

variable "vpc_public_subnets" {
  description = "VPC Public Subnets"
  type        = list(string)
}

variable "vpc_private_subnets" {
  description = "VPC Private Subnets"
  type        = list(string)
}

variable "vpc_enable_nat_gateway" {
  description = "Enable NAT Gateways for Private Subnets Outbound Communication"
  type        = bool
  default     = true
}

variable "vpc_single_nat_gateway" {
  description = "Enable only single NAT Gateway in one Availability Zone to save costs during our demos"
  type        = bool
  default     = true
}



## EC2

variable "ssh_ec2_instance_type" {
  type        = string
  description = "instance type of ssh host"
  default     = "t2.micro"

}
variable "ssh_ec2_keypair" {
  type        = string
  description = "keypair for ssh host"
}


########### EKS 
variable "eks_cluster_name" {
  type = string
  description = "eks cluster name"
  default = "eks-demo"
}

variable "eks_ipv4_cidr_range" {
  description = "service ipv4 cidr for eks"
  type = string
  default = null 
}

variable "eks_cluster_version" {
  description = "kubernetes minor version to use for eks"
  type = string
  default = null 
}

variable "eks_cluster_endpoint_public_access" {
  description = "determines if public access to api server is exposed or not"
  type = bool
  default = true
}

variable "eks_cluster_endpoint_private_access" {
  description = "determines if private access to api server is exposed or not"
  type = bool
  default = false
}

variable "eks_cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks which can access the Amazon EKS public API server endpoint."
  type        = list(string)
  default     = ["0.0.0.0/0"] 
}