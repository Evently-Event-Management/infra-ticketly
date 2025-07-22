resource "keycloak_realm" "event_ticketing" {
  realm        = "event-ticketing"
  enabled      = true
  display_name = "Event Ticketing Platform"

  registration_allowed            = true
  registration_email_as_username = true
  remember_me                     = true
  verify_email                    = true
  login_with_email_allowed        = true
  duplicate_emails_allowed        = false
  reset_password_allowed          = true
  edit_username_allowed           = false
  brute_force_protected           = true
}

resource "keycloak_smtp_server" "smtp" {
  realm_id        = keycloak_realm.event_ticketing.id
  from            = "noreply@eventtickets.local"
  from_display_name = "Event Ticketing Platform"
  host            = "smtp.gmail.com"
  port            = 587
  starttls        = true
  ssl             = false
  auth            = false
}

resource "keycloak_role" "system_admin" {
  realm_id = keycloak_realm.event_ticketing.id
  name     = "role-system-admin"
  description = "Platform administrators who can approve events and manage system"
}

resource "keycloak_role" "user" {
  realm_id = keycloak_realm.event_ticketing.id
  name     = "role-user"
  description = "General users who can create and manage events"
}

resource "keycloak_default_roles" "default_roles" {
  realm_id = keycloak_realm.event_ticketing.id
  default_roles = [
    keycloak_role.user.name
  ]
}
