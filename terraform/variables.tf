variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "eks-observability"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}
