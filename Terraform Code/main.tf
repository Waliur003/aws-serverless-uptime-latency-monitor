// Declare the terraform block and specify the required version of Terraform and providers
terraform {
  required_version = ">= 0.15.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }
}


// Declare the AWS provider and configure the region and default tags
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = "Website-Uptime-Monitor"
      ManagedBy = "Terraform"
    }
  }
}