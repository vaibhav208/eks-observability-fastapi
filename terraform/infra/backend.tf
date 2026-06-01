terraform {
  backend "s3" {
    bucket         = "eks-observability-tf-state-800309353239"
    key            = "infra/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "eks-observability-tf-lock"
    encrypt        = true
  }
}
