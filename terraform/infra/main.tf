data "aws_availability_zones" "available" {}

module "network" {
  source       = "./modules/network"
  project_name = var.project_name
  environment  = var.environment
}

module "iam" {
  source       = "./modules/iam"
  project_name = var.project_name
  github_oidc_provider_arn = aws_iam_openid_connect_provider.github.arn
}

module "eks" {
  source = "./modules/eks"

  project_name       = var.project_name
  cluster_role_arn   = module.iam.eks_cluster_role_arn
  node_role_arn      = module.iam.eks_node_role_arn
  private_subnet_ids = module.network.private_subnet_ids

  depends_on = [module.iam]
}

module "bastion" {
  source           = "./modules/bastion"
  project_name     = var.project_name
  vpc_id           = module.network.vpc_id
  public_subnet_id = module.network.public_subnet_ids[0]
}

module "ecr" {
  source       = "./modules/ecr"
  project_name = var.project_name
}
