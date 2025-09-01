#==================================================================
# 1. DEFINE FINE-GRAINED REALM ROLES
# These represent specific actions, not user types.
#==================================================================
resource "keycloak_role" "event_admin" {
  realm_id = keycloak_realm.event_ticketing.id
  name     = "event_admin"
}

resource "keycloak_role" "category_admin" {
  realm_id = keycloak_realm.event_ticketing.id
  name     = "category_admin"
}

resource "keycloak_role" "organization_admin" {
  realm_id = keycloak_realm.event_ticketing.id
  name     = "organization_admin"
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
    # System Admins are directly assigned the specific, fine-grained realm roles below,
    # and also inherit the base account management roles from the parent "Users" group.
    keycloak_role.event_admin.id,
    keycloak_role.category_admin.id,
    keycloak_role.organization_admin.id
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
