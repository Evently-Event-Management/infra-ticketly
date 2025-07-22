resource "keycloak_openid_client" "events_service" {
  realm_id            = keycloak_realm.event_ticketing.id
  client_id           = "events-service"
  name                = "Events Microservice"
  enabled             = true
  bearer_only         = true
  public_client       = false
  direct_access_grants_enabled = false
  service_accounts_enabled     = false
}

resource "keycloak_openid_client" "login_testing" {
  realm_id            = keycloak_realm.event_ticketing.id
  client_id           = "login-testing"
  name                = "Login Testing Client"
  enabled             = true
  bearer_only         = false
  public_client       = true
  direct_access_grants_enabled = true
  service_accounts_enabled     = false
}
