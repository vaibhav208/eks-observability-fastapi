data "terraform_remote_state" "infra" {
  backend = "s3"

  config = {
    bucket = "eks-observability-tf-state-800309353239"
    key    = "infra/terraform.tfstate"
    region = "us-east-1"
  }
}
