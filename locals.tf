locals {
  full_name = "${var.customer}-${var.env}"
  full_name_eks_cluster = "${local.full_name}-${var.eks_cluster_name}"
  tags = {
    customer = var.customer
    env      = var.env
  }
}
