#==================================================================
# 1. CREATE A REUSABLE CLIENT SCOPE FOR GROUPS
#==================================================================
resource "keycloak_openid_client_scope" "group_membership_scope" {
  realm_id = keycloak_realm.event_ticketing.id
  name     = "group_membership"
  description = "Adds user group memberships to the token."
}

#==================================================================
# 2. CREATE THE GROUP MEMBERSHIP MAPPER
# This mapper will read a user's groups and add them to a custom claim.
#==================================================================
resource "keycloak_openid_group_membership_protocol_mapper" "group_membership_mapper" {
  realm_id        = keycloak_realm.event_ticketing.id
  client_scope_id = keycloak_openid_client_scope.group_membership_scope.id
  name            = "group-membership-mapper"
  claim_name      = "user_groups"
  full_path       = true

  # These ensure the claim is included in the respective tokens.
  add_to_id_token     = true
  add_to_access_token = true
  add_to_userinfo     = true
}

#==================================================================
# 3. ATTACH THE SCOPE TO YOUR CLIENT
#==================================================================

#Login Testing Client - Public client for testing purposes
resource "keycloak_openid_client_default_scopes" "login_testing_default_scopes" {
  realm_id  = keycloak_realm.event_ticketing.id
  client_id = keycloak_openid_client.login_testing.id

  # Get the existing default scopes and add our new one.
  default_scopes = [
    "roles",
    "basic",
    keycloak_openid_client_scope.group_membership_scope.name
  ]
}

# Frontend App Client - Public client for Next.js SPA
resource "keycloak_openid_client_default_scopes" "frontend_app_default_scopes" {
  realm_id  = keycloak_realm.event_ticketing.id
  client_id = keycloak_openid_client.frontend_app.id

  # Get the existing default scopes and add our new one.
  default_scopes = [
    "profile",
    "email",
    "roles",
    "basic",
    keycloak_openid_client_scope.group_membership_scope.name
  ]
}



# ===================================================================
# 4. Client Scope for internal API
# This scope will be used by internal API for m2m communication.
# ===================================================================
resource "keycloak_openid_client_scope" "internal_api_scope" {
  realm_id = keycloak_realm.event_ticketing.id
  name     = "internal-api"
}


resource "keycloak_openid_client_default_scopes" "api_gateway_default_scopes" {
  realm_id  = keycloak_realm.event_ticketing.id
  client_id = keycloak_openid_client.api_gateway.id

  default_scopes = [
    keycloak_openid_client_scope.internal_api_scope.name
  ]
}

resource "keycloak_openid_client_default_scopes" "scheduler_service_default_scopes" {
  realm_id  = keycloak_realm.event_ticketing.id
  client_id = keycloak_openid_client.scheduler_service.id

  default_scopes = [
    keycloak_openid_client_scope.internal_api_scope.name
  ]
}

resource "keycloak_openid_client_default_scopes" "event_projection_service_default_scopes" {
  realm_id  = keycloak_realm.event_ticketing.id
  client_id = keycloak_openid_client.event_projection_service.id

  default_scopes = [
    keycloak_openid_client_scope.internal_api_scope.name
  ]
}