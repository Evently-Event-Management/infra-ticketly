terraform {
  required_version = ">= 1.5"

  backend "remote" {
    organization = "ticketly-org"
    workspaces {
      prefix = "infra-dev-"
    }
  }

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
