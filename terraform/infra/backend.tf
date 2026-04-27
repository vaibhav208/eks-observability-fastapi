terraform {
  backend "s3" {
    bucket         = "eks-observability-tf-state-797671034493"
    key            = "infra/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "eks-observability-tf-lock"
    encrypt        = true
  }
}
