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

output "system_admins_group_id" {
  description = "The ID of the System Admins group"
  value       = keycloak_group.system_admins.id
}

output "users_group_id" {
  description = "The ID of the Users group"
  value       = keycloak_group.users.id
}

output "events_service_client_id" {
  description = "The client ID of the events service"
  value       = keycloak_openid_client.events_service.client_id
}

output "login_testing_client_id" {
  description = "The client ID of the login testing client"
  value       = keycloak_openid_client.login_testing.client_id
}

output "api_gateway_client_secret" {
  value     = keycloak_openid_client.api_gateway.client_secret
  sensitive = true # Hides the value from standard output logs
}

output "scheduler_service_client_secret" {
  value     = keycloak_openid_client.scheduler_service.client_secret
  sensitive = true
}
