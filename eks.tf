module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.19.0"

  # --- Attrs
  name            = local.full_name
  cidr            = var.vpc_cidr_block
  azs             = [data.aws_availability_zones.azs.names[0],data.aws_availability_zones.azs.names[1]]
  #private_subnets = var.vpc_private_subnets
  public_subnets  = var.vpc_public_subnets
  #single_nat_gateway = var.vpc_single_nat_gateway
  #enable_nat_gateway = var.vpc_enable_nat_gateway
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = local.tags
  public_subnet_tags = {
    Type = "Public Subnets"
    "kubernetes.io/role/elb" = 1    
    "kubernetes.io/cluster/${local.full_name_eks_cluster}" = "shared"        
  }
#  private_subnet_tags = {
#    Type = "Private Subnets"
#    "kubernetes.io/role/internal-elb" = 1    
#    "kubernetes.io/cluster/${local.full_name_eks_cluster}" = "shared"    
#  }

}

data "aws_availability_zones" "azs" {
  state = "available"
}

# security group for ec2 server
module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.17.1"

  name                = local.full_name
  description         = "Security group which is used as an argument in complete-sg"
  vpc_id              = module.vpc.vpc_id
  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["ssh-tcp"]
  egress_rules        = ["all-all"]
  tags                = local.tags
}

# Amazon Linux 2 AMI
data "aws_ami" "amazonlinux2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-gp2"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "4.3.0"

  # Required Arguements 
  name                   = local.full_name
  ami                    = data.aws_ami.amazonlinux2.id
  instance_type          = var.ssh_ec2_instance_type
  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [module.security_group.security_group_id]
  key_name               = var.ssh_ec2_keypair
  
#  provisioner "file" {
#    source = "./ec2-ssh-key/ssh-keypair.pem"
#    destination = "/home/ec2-user/ssh-keypair.pem"
#  
#  }
  tags = local.tags
}

resource "aws_eip" "ssh_eip" {
  instance = module.ec2_instance.id
  vpc      = true

  tags = local.tags

  depends_on = [
    module.ec2_instance,
    module.vpc
  ]
}

# EKS Controlplane Role
resource "aws_iam_role" "eks_controlplane_role" {
  name = "${local.full_name_eks_cluster}-controlplane-role"

  assume_role_policy = jsonencode(
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
})

}

resource "aws_iam_role_policy_attachment" "eks_controlplane_role-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role = aws_iam_role.eks_controlplane_role.name
}
resource "aws_iam_role_policy_attachment" "eks_controlplane_role-AmazonEKSVPCResourceController" {
  role = aws_iam_role.eks_controlplane_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"

}

# EKS Nodegroup Role

resource "aws_iam_role" "eks_nodegroup_role" {
  name = "${local.full_name_eks_cluster}-nodegroup-role"
  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "eks_nodegroup_role-AmazonEKSWorkerNodePolicy" {
  role = aws_iam_role.eks_nodegroup_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"

}
resource "aws_iam_role_policy_attachment" "eks_nodegroup_role-AmazonEKS_CNI_Policy" {
  role = aws_iam_role.eks_nodegroup_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"

}
resource "aws_iam_role_policy_attachment" "eks_nodegroup_role-AmazonEC2ContainerRegistryReadOnly" {
  role = aws_iam_role.eks_nodegroup_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  
}


## EKS 

resource "aws_eks_cluster" "eks_cluster" {
  name     = local.full_name_eks_cluster
  role_arn = aws_iam_role.eks_controlplane_role.arn
  version = var.eks_cluster_version
  
  vpc_config {
    subnet_ids = module.vpc.public_subnets
    endpoint_private_access = var.eks_cluster_endpoint_private_access
    endpoint_public_access  = var.eks_cluster_endpoint_public_access
    public_access_cidrs     = var.eks_cluster_endpoint_public_access_cidrs    
  }

  kubernetes_network_config {
    service_ipv4_cidr = var.eks_ipv4_cidr_range
  }
  depends_on = [
    aws_iam_role_policy_attachment.eks_controlplane_role-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.eks_controlplane_role-AmazonEKSVPCResourceController,
  ]

}

resource "aws_eks_node_group" "public_nodegroup" {
  cluster_name = aws_eks_cluster.eks_cluster.name
  node_group_name = "${aws_eks_cluster.eks_cluster.name}-ng-public"
  node_role_arn = aws_iam_role.eks_nodegroup_role.arn
  subnet_ids = module.vpc.public_subnets

  ami_type = "AL2_x86_64"  
  capacity_type = "ON_DEMAND"
  disk_size = 20
  instance_types = ["t3.medium"]

  remote_access {
    ec2_ssh_key = var.ssh_ec2_keypair
  }
  scaling_config {
    desired_size = 2
    max_size = 2
    min_size = 2
  }

  update_config {
    max_unavailable = 1
  }
  
  depends_on = [
    aws_iam_role_policy_attachment.eks_nodegroup_role-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks_nodegroup_role-AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.eks_nodegroup_role-AmazonEKS_CNI_Policy,
  ]

}