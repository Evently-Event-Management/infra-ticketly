resource "keycloak_user" "admin_user" {
  realm_id = keycloak_realm.event_ticketing.id
  username = "admin@yopmail.com"
  email    = "admin@yopmail.com"
  first_name = "System"
  last_name  = "Admin"
  enabled = true
  email_verified = true

  initial_password {
    value     = "admin123"
    temporary = false
  }

  realm_roles = [keycloak_role.system_admin.name]
}

resource "keycloak_user" "event_user" {
  realm_id = keycloak_realm.event_ticketing.id
  username = "user@yopmail.com"
  email    = "user@yopmail.com"
  first_name = "Event"
  last_name  = "User"
  enabled = true
  email_verified = true

  initial_password {
    value     = "user123"
    temporary = false
  }

  realm_roles = [keycloak_role.user.name]
}
