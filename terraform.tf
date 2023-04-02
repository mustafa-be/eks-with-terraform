terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  backend "s3" {
    bucket = "eks-remote-state-101"
    key = "eks-cluster-state/terraform.tfstate"
    region = "us-east-1"
    dynamodb_table = "eks-cluster-state"
  }
}

provider "aws" {
  region = var.region
}

