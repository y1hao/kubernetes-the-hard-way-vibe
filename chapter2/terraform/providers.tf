terraform {
  required_version = ">= 1.13.3, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "terraform_remote_state" "chapter1" {
  backend = "local"

  config = {
    path = "${path.module}/../../chapter1/terraform/terraform.tfstate"
  }
}
