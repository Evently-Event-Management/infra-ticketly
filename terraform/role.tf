data "keycloak_openid_client" "account" {
  realm_id  = keycloak_realm.event_ticketing.id
  client_id = "account"
}

data "keycloak_role" "manage_account" {
  realm_id  = keycloak_realm.event_ticketing.id
  client_id = data.keycloak_openid_client.account.id
  name      = "manage-account"
}

data "keycloak_role" "view_profile" {
  realm_id  = keycloak_realm.event_ticketing.id
  client_id = data.keycloak_openid_client.account.id
  name      = "view-profile"
}




# Create realm roles
resource "keycloak_role" "system_admin" {
  realm_id    = keycloak_realm.event_ticketing.id
  name        = "system-admin"
  description = "Platform administrators who can approve events and manage system"
  composite_roles = [
    data.keycloak_role.manage_account.id,
    data.keycloak_role.view_profile.id
  ]
}

resource "keycloak_role" "user" {
  realm_id    = keycloak_realm.event_ticketing.id
  name        = "user"
  description = "General users who can create and manage events"
  composite_roles = [
    data.keycloak_role.manage_account.id,
    data.keycloak_role.view_profile.id
  ]
}


resource "keycloak_default_roles" "default_roles" {
  realm_id      = keycloak_realm.event_ticketing.id
  default_roles = [keycloak_role.user.name]
}