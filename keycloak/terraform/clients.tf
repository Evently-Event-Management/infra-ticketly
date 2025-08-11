# Events Microservice Client - Bearer Only for API access
resource "keycloak_openid_client" "events_service" {
  realm_id  = keycloak_realm.event_ticketing.id
  client_id = "events-service"
  name      = "Events Microservice"
  enabled   = true
  
  access_type                      = "BEARER-ONLY"
  service_accounts_enabled         = false
  direct_access_grants_enabled     = false
  standard_flow_enabled           = false
  implicit_flow_enabled           = false
}

# Login Testing Client - Public client for testing purposes
resource "keycloak_openid_client" "login_testing" {
  realm_id  = keycloak_realm.event_ticketing.id
  client_id = "login-testing"
  name      = "Login Testing Client"
  enabled   = true
  
  access_type                      = "PUBLIC"
  service_accounts_enabled         = false
  direct_access_grants_enabled     = true
  standard_flow_enabled           = true
  implicit_flow_enabled           = false
  
  valid_redirect_uris = [
    "http://localhost:3000/*",
    "http://localhost:8080/*",
    "https://localhost:3000/*",
    "https://localhost:8080/*"
  ]
}

resource "keycloak_openid_client" "frontend_app" {
  realm_id                     = keycloak_realm.event_ticketing.id
  client_id                    = "web-frontend"
  name                         = "Frontend SPA (Next.js)"
  enabled                      = true

  access_type                  = "PUBLIC"
  standard_flow_enabled        = true         # Authorization Code with PKCE
  implicit_flow_enabled        = false
  direct_access_grants_enabled = false        # No password flow

  valid_redirect_uris = [
    "http://localhost:8090/*",
    "https://localhost:8090/*"
  ]

  web_origins = [
    "http://localhost:8090",
    "https://localhost:8090"
  ]
}


# API Gateway Client - Confidential client for token validation
resource "keycloak_openid_client" "api_gateway" {
  realm_id                = keycloak_realm.event_ticketing.id
  client_id               = "api-gateway-client"
  name                    = "API Gateway"
  enabled                 = true
  access_type             = "CONFIDENTIAL"
  standard_flow_enabled      = false
  implicit_flow_enabled      = false
  direct_access_grants_enabled = false
  service_accounts_enabled = true 
}


resource "keycloak_openid_client" "scheduler_service" {
  realm_id               = keycloak_realm.event_ticketing.id
  client_id              = "scheduler-service-client"
  name                   = "Scheduler Service"
  enabled                = true
  access_type            = "CONFIDENTIAL"
    standard_flow_enabled      = false
  direct_access_grants_enabled = false
  service_accounts_enabled = true
}