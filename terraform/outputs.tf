# Output important resource information
output "realm_id" {
  description = "The ID of the created realm"
  value       = keycloak_realm.event_ticketing.id
}

output "realm_name" {
  description = "The name of the created realm"
  value       = keycloak_realm.event_ticketing.realm
}

output "admin_user_id" {
  description = "The ID of the admin user"
  value       = keycloak_user.admin.id
}

output "regular_user_id" {
  description = "The ID of the regular user"
  value       = keycloak_user.user.id
}

output "system_admin_role_id" {
  description = "The ID of the system admin role"
  value       = keycloak_role.system_admin.id
}

output "user_role_id" {
  description = "The ID of the user role"
  value       = keycloak_role.user.id
}

output "events_service_client_id" {
  description = "The client ID of the events service"
  value       = keycloak_openid_client.events_service.client_id
}

output "login_testing_client_id" {
  description = "The client ID of the login testing client"
  value       = keycloak_openid_client.login_testing.client_id
}