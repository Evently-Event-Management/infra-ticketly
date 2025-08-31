variable "public_key_content" {
  description = "Public key content for the EC2 key pair"
  type        = string
}

variable "rds_user" {
  description = "The username for the RDS database"
  type        = string
}

variable "rds_password" {
  description = "The password for the RDS database"
  type        = string
  sensitive   = true
}