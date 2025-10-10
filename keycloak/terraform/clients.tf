# Events Microservice Client - Bearer Only for API access
resource "keycloak_openid_client" "events_service" {
  realm_id  = keycloak_realm.event_ticketing.id
  client_id = "events-service"
  name      = "Events Microservice"
  enabled   = true

  access_type                      = "CONFIDENTIAL"
  service_accounts_enabled         = true
  direct_access_grants_enabled     = false
  standard_flow_enabled           = false
  implicit_flow_enabled           = false
}

# Role assign
data "keycloak_openid_client" "realm_management" {
  realm_id  = keycloak_realm.event_ticketing.id
  client_id = "realm-management"
}

data "keycloak_role" "events_service_manage_users" {
  realm_id  = keycloak_realm.event_ticketing.id
  client_id = data.keycloak_openid_client.realm_management.id
  name      = "manage-users"
}

resource "keycloak_openid_client_service_account_role" "events_service_manage_users" {
  realm_id                = keycloak_realm.event_ticketing.id
  service_account_user_id = keycloak_openid_client.events_service.service_account_user_id
  client_id               = data.keycloak_openid_client.realm_management.id
  role                    = data.keycloak_role.events_service_manage_users.name
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

  web_origins = [
    "http://localhost:8082",
    "http://localhost:8083",
    "http://ticketly.test:8090"
    ]
  
  valid_redirect_uris = [
    "http://localhost:3000/*",
    "http://localhost:8080/*",
    "http://ticketly.test:8090/*",
    "https://localhost:3000/*",
    "https://localhost:8080/*",
    "https://ticketly.test:8090/*"
  ]
}

resource "keycloak_openid_client" "frontend_app" {
  realm_id                     = keycloak_realm.event_ticketing.id
  client_id                    = "web-frontend"
  name                         = "Frontend SPA (Next.js)"
  enabled                      = true

  access_type                  = "PUBLIC"
  standard_flow_enabled        = true
  pkce_code_challenge_method   = "S256"
  implicit_flow_enabled        = false
  direct_access_grants_enabled = false

  valid_redirect_uris = [
    "http://localhost:8090/*",
    "https://localhost:8090/*",
    "http://www.localhost:8090/*",
    "https://www.localhost:8090/*",
    "http://ticketly.test:8090/*",
    "https://ticketly.test:8090/*",
    "https://ticketly.dpiyumal.me/*"
  ]

  web_origins = [
    "http://localhost:8090",
    "https://localhost:8090",
    "http://www.localhost:8090",
    "https://www.localhost:8090",
    "http://ticketly.test:8090",
    "https://ticketly.test:8090",
    "https://ticketly.dpiyumal.me"
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


data "keycloak_role" "scheduler_service_view_users" {
  realm_id  = keycloak_realm.event_ticketing.id
  client_id = data.keycloak_openid_client.realm_management.id
  name      = "view-users"
}

resource "keycloak_openid_client_service_account_role" "scheduler_service_view_users" {
  realm_id                = keycloak_realm.event_ticketing.id
  service_account_user_id = keycloak_openid_client.scheduler_service.service_account_user_id
  client_id               = data.keycloak_openid_client.realm_management.id
  role                    = data.keycloak_role.scheduler_service_view_users.name
}

resource "keycloak_openid_client" "event_projection_service" {
  realm_id               = keycloak_realm.event_ticketing.id
  client_id              = "event-projection-service-client"
  name                   = "Event Projection Service"
  enabled                = true
  access_type            = "CONFIDENTIAL"
  standard_flow_enabled      = false
  direct_access_grants_enabled = false
  service_accounts_enabled = true
}

resource "keycloak_openid_client" "ticket_service" {
  realm_id               = keycloak_realm.event_ticketing.id
  client_id              = "ticket-service-client"
  name                   = "Ticket Service"
  enabled                = true
  access_type            = "CONFIDENTIAL"
  standard_flow_enabled      = false
  direct_access_grants_enabled = false
  service_accounts_enabled = true
}

resource "keycloak_openid_client" "payment_service" {
  realm_id               = keycloak_realm.event_ticketing.id
  client_id              = "payment-service-client"
  name                   = "Payment Service"
  enabled                = true
  access_type            = "CONFIDENTIAL"
  standard_flow_enabled      = false
  direct_access_grants_enabled = false
  service_accounts_enabled = true
  
}