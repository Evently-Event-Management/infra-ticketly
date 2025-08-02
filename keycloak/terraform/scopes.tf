#==================================================================
# 1. CREATE A REUSABLE CLIENT SCOPE FOR GROUPS
#==================================================================
resource "keycloak_openid_client_scope" "group_membership_scope" {
  realm_id = keycloak_realm.event_ticketing.id
  name     = "group_membership"

  # Optional: Description for clarity in the Keycloak UI
  description = "Adds user group memberships to the token."
}

#==================================================================
# 2. CREATE THE GROUP MEMBERSHIP MAPPER
# This mapper will read a user's groups and add them to a custom claim.
# ✅ Using the dedicated resource for group membership mapping.
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
# This example assumes you have a client defined with the resource
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
