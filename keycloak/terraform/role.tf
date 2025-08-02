#==================================================================
# 1. DEFINE FINE-GRAINED REALM ROLES
# These represent specific actions, not user types.
#==================================================================
resource "keycloak_role" "approve_event" {
  realm_id = keycloak_realm.event_ticketing.id
  name     = "approve_event"
}

resource "keycloak_role" "manage_categories" {
  realm_id = keycloak_realm.event_ticketing.id
  name     = "manage_categories"
}

#==================================================================
# 2. CREATE THE GROUP HIERARCHY
#==================================================================

# --- Parent Groups (Folders) ---
resource "keycloak_group" "permissions_parent" {
  realm_id = keycloak_realm.event_ticketing.id
  name     = "Permissions"
}

resource "keycloak_group" "tiers_parent" {
  realm_id = keycloak_realm.event_ticketing.id
  name     = "Tiers"
}

# --- Permissions Sub-Groups ---
resource "keycloak_group" "users" {
  realm_id  = keycloak_realm.event_ticketing.id
  parent_id = keycloak_group.permissions_parent.id
  name      = "Users"
}

# ✅ System Admins is now a child of the Users group
resource "keycloak_group" "system_admins" {
  realm_id  = keycloak_realm.event_ticketing.id
  parent_id = keycloak_group.users.id
  name      = "System Admins"
}

# --- Tiers Sub-Groups ---
resource "keycloak_group" "tier_free" {
  realm_id  = keycloak_realm.event_ticketing.id
  parent_id = keycloak_group.tiers_parent.id
  name      = "FREE"
}

resource "keycloak_group" "tier_pro" {
  realm_id  = keycloak_realm.event_ticketing.id
  parent_id = keycloak_group.tiers_parent.id
  name      = "PRO"
}

resource "keycloak_group" "tier_enterprise" {
  realm_id  = keycloak_realm.event_ticketing.id
  parent_id = keycloak_group.tiers_parent.id
  name      = "ENTERPRISE"
}


#==================================================================
# 3. ASSIGN ROLES TO GROUPS
# This is where the magic happens.
#==================================================================

# Data sources for the built-in account management roles
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

# Assign account management client roles to the "Users" group
resource "keycloak_group_roles" "users_group_roles" {
  realm_id = keycloak_realm.event_ticketing.id
  group_id = keycloak_group.users.id

  # They only get the basic account management client roles
  role_ids = [
    data.keycloak_role.manage_account.id,
    data.keycloak_role.view_profile.id
  ]
}

# Assign elevated roles to the "System Admins" group
resource "keycloak_group_roles" "system_admins_group_roles" {
  realm_id = keycloak_realm.event_ticketing.id
  group_id = keycloak_group.system_admins.id

  role_ids = [
    # They only need the specific, fine-grained realm roles.
    # The base roles are inherited from the parent "Users" group.
    keycloak_role.approve_event.id,
    keycloak_role.manage_categories.id,
  ]
}


#==================================================================
# 4. SET DEFAULT GROUPS FOR NEW USERS
#==================================================================
resource "keycloak_default_groups" "default_groups" {
  realm_id = keycloak_realm.event_ticketing.id
  group_ids = [
    keycloak_group.users.id,
    keycloak_group.tier_free.id
  ]
}
