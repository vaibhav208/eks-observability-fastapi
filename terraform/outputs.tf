output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "eks_cluster_name" {
  value = aws_eks_cluster.this.name
}

output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

output "ecr_repository_url" {
  value = aws_ecr_repository.fastapi.repository_url
}
