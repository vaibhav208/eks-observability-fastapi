data "terraform_remote_state" "infra" {
  backend = "s3"

  config = {
    bucket = "eks-observability-tf-state-797671034493"
    key    = "infra/terraform.tfstate"
    region = "us-east-1"
  }
}
