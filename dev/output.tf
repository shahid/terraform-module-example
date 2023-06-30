# VPC Settings
output "vpc_id" {
  description = "The ID of the VPC"
  value = module.dev_vpc.vpc_id
}

output "public_subnets_id" {
  description = "Public subnet id's for common infra like EC2's or Load Balancers"
  value = module.dev_vpc.public_subnets_id
}

output "public_eks_subnets_id" {
  description = "Public subnet id's for EKS cluster"
  value = module.dev_vpc.public_eks_subnets_id
}

output "private_subnets_id" {
  description = "Private subnet id's for common infra's"
  value = module.dev_vpc.private_subnets_id
}

output "private_eks_subnets_id" {
  description = "Private subnet id's for EKS "
  value = module.dev_vpc.private_eks_subnets_id
}

output "private_rds_dubnets_id" {
  description = "Private subnet id's for DB's and RDS"
  value = module.dev_vpc.private_rds_subnets_id
}

#EKS Settings
output "eks_cluster_endpoint" {
  value = module.development_eks_cluster.eks_cluster_endpoint
}

output "kubeconfig-certificate-authority-data" {
  value = module.development_eks_cluster.kubeconfig_certificate_authority_data
}



