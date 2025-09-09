terraform {
  required_version = ">= 1.5"

  # Updated backend to support multiple workspaces under a common prefix
  backend "remote" {
    organization = "ticketly-org"
    workspaces {
      prefix = "infra-"
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

locals {
  is_prod = terraform.workspace == "infra-ticketly"
}