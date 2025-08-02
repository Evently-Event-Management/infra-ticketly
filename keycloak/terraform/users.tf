# Admin user
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

# Regular user
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

# ✅ Assign the admin user to the "System Admins" group and a tier
resource "keycloak_user_groups" "admin_user_groups" {
  realm_id = keycloak_realm.event_ticketing.id
  user_id  = keycloak_user.admin.id

  group_ids = [
    # This user gets all permissions from the System Admins group
    keycloak_group.system_admins.id,
    # Example: Assign the admin to the PRO tier
    keycloak_group.tier_pro.id
  ]
}

# ✅ Assign the regular user to the "Users" group and a tier
# Note: Since "Users" and "FREE" are default groups, this is explicit but optional.
# It's useful if you need to assign existing users.
resource "keycloak_user_groups" "regular_user_groups" {
  realm_id = keycloak_realm.event_ticketing.id
  user_id  = keycloak_user.user.id

  group_ids = [
    # This user gets base permissions from the Users group
    keycloak_group.users.id,
    # This user is on the FREE tier
    keycloak_group.tier_free.id
  ]
}
