terraform {
  required_providers {
    keycloak = {
      source = "keycloak/keycloak"
      version = ">= 5.0.0"
    }
  }
}

provider "keycloak" {
  client_id = "admin-cli"
  username  = var.keycloak_admin_username
  password  = var.keycloak_admin_password
  url       = var.keycloak_url
  realm     = "master"
}

terraform { 
  cloud { 
    
    organization = "ticketly-org" 

    workspaces { 
      name = "ticketly-keycloak" 
    } 
  } 
}
