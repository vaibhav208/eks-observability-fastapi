output "vpc_id" {
  value = module.network.vpc_id
}

output "public_subnet_ids" {
  value = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.network.private_subnet_ids
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "bastion_public_ip" {
  value = module.bastion.public_ip
}

output "ecr_repository_url" {
  value = module.ecr.repository_url
}

output "eks_node_role_arn" {
  value = module.iam.eks_node_role_arn
}

output "bastion_role_arn" {
  value = module.bastion.bastion_role_arn
}
