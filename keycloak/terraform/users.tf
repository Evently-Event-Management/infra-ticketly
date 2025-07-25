# Admin user with system administrator role
resource "keycloak_user" "admin" {
  realm_id       = keycloak_realm.event_ticketing.id
  username       = "admin@yopmail.com"
  enabled        = true
  email          = "admin@yopmail.com"
  email_verified = true
  first_name     = "System"
  last_name      = "Admin"
  
  initial_password {
    value     = "admin123"
    temporary = false
  }
}

# Regular user with standard user role
resource "keycloak_user" "user" {
  realm_id       = keycloak_realm.event_ticketing.id
  username       = "user@yopmail.com"
  enabled        = true
  email          = "user@yopmail.com"
  email_verified = true
  first_name     = "Event"
  last_name      = "User"
  
  initial_password {
    value     = "user123"
    temporary = false
  }
}

# Assign system admin role to admin user
resource "keycloak_user_roles" "admin_roles" {
  realm_id = keycloak_realm.event_ticketing.id
  user_id  = keycloak_user.admin.id
  
  role_ids = [
    keycloak_role.system_admin.id
  ]
}

# Assign user role to regular user
resource "keycloak_user_roles" "user_roles" {
  realm_id = keycloak_realm.event_ticketing.id
  user_id  = keycloak_user.user.id
  
  role_ids = [
    keycloak_role.user.id
  ]
}