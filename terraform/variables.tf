# Optional variables for customization
variable "realm_name" {
  description = "The name of the Keycloak realm"
  type        = string
  default     = "event-ticketing"
}

variable "realm_display_name" {
  description = "The display name of the Keycloak realm"
  type        = string
  default     = "Event Ticketing Platform"
}

variable "smtp_host" {
  description = "SMTP server host"
  type        = string
  default     = "smtp.gmail.com"
}

variable "smtp_port" {
  description = "SMTP server port"
  type        = string
  default     = "587"
}

variable "smtp_from_email" {
  description = "SMTP from email address"
  type        = string
  default     = "noreply@eventtickets.local"
}

variable "smtp_from_password" {
  description = "SMTP from email password"
  type        = string
  default     = "your_smtp_password"
  sensitive   = true     
}

variable "smtp_from_display_name" {
  description = "SMTP from display name"
  type        = string
  default     = "Ticketly Event Ticketing Platform"
}

variable "admin_email" {
  description = "Admin user email"
  type        = string
  default     = "admin@yopmail.com"
}

variable "admin_password" {
  description = "Admin user password"
  type        = string
  default     = "admin123"
  sensitive   = true
}

variable "regular_user_email" {
  description = "Regular user email"
  type        = string
  default     = "user@yopmail.com"
}

variable "regular_user_password" {
  description = "Regular user password"
  type        = string
  default     = "user123"
  sensitive   = true
}

variable "keycloak_admin_username" {
  description = "Keycloak admin username"
  type        = string
  default     = "admin"
}

variable "keycloak_admin_password" {
  description = "Keycloak admin password"
  type        = string
  default     = "admin123"
}

variable "keycloak_url" {
  description = "URL of the Keycloak server"
  type        = string
  default     = "http://localhost:8080"
}