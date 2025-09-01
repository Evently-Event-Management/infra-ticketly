terraform {
  required_version = ">= 1.5"

  backend "remote" {
    organization = "ticketly-org" # your Terraform Cloud org

    workspaces {
      name = "infra-ticketly"
    }
  }
}
