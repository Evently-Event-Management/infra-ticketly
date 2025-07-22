# Create realm roles
resource "keycloak_role" "system_admin" {
  realm_id    = keycloak_realm.event_ticketing.id
  name        = "role-system-admin"
  description = "Platform administrators who can approve events and manage system"
}

resource "keycloak_role" "user" {
  realm_id    = keycloak_realm.event_ticketing.id
  name        = "role-user"
  description = "General users who can create and manage events"
}

resource "keycloak_default_roles" "default_roles" {
  realm_id      = keycloak_realm.event_ticketing.id
  default_roles = ["role-user"]
}