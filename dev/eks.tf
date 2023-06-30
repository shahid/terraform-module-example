locals {
  cluster_name                           = "eks-${var.env}-${var.client}"
  cluster_version                        = "1.27"
  eks_cluster_iam_role                   = "iam-role-eks-cluster-role"
  eks_public_access_cidr                 = "0.0.0.0/0"
  eks_managed_worker_nodes_name          = "workernodes-${var.env}-${var.client}"
  eks_iam_autoscaling_workernode         = "${var.client}-eks-cluster-autoscaling-policy"
  eks_iam_secrets_read_workernode        = "${var.client}-eks-cluster-secrets-read-policy"
  eks_managed_worker_nodes_desired_size  = 2
  eks_managed_worker_nodes_max_size      = 2
  eks_managed_worker_nodes_min_size      = 1
  eks_managed_worker_nodes_ami_type      = "AL2_x86_64"
  eks_managed_worker_nodes_disk_size     = "30"
  eks_managed_worker_nodes_instance_type = ["t3.xlarge"]
}

module "development_eks_cluster" {
  source                                 = "../modules/eks"
  cluster_name                           = local.cluster_name
  cluster_version                        = local.cluster_version
  eks_cluster_iam_role                   = local.eks_cluster_iam_role
  #eks_public_subnets                     = ["${module.dev_vpc.public_eks_subnets_id}"]
  eks_public_subnets                     = module.dev_vpc.public_eks_subnets_id
  eks_public_access_cidr                 = local.eks_public_access_cidr
  eks_private_subnets                    = module.dev_vpc.private_eks_subnets_id
  #eks_private_subnets                    = ["${module.dev_vpc.private_subnet_eks1_id}", "${module.dev_vpc.private_subnet2_id}"]
  eks_managed_worker_nodes_name          = local.eks_managed_worker_nodes_name
  eks_managed_worker_nodes_desired_size  = local.eks_managed_worker_nodes_desired_size
  eks_managed_worker_nodes_max_size      = local.eks_managed_worker_nodes_max_size
  eks_managed_worker_nodes_min_size      = local.eks_managed_worker_nodes_min_size
  eks_managed_worker_nodes_ami_type      = local.eks_managed_worker_nodes_ami_type
  eks_managed_worker_nodes_disk_size     = local.eks_managed_worker_nodes_disk_size
  eks_managed_worker_nodes_instance_type = local.eks_managed_worker_nodes_instance_type
  eks_iam_autoscaling_workernode         = local.eks_iam_autoscaling_workernode
  eks_iam_secrets_read_workernode        = local.eks_iam_secrets_read_workernode
}
