variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
  default     = "ap-south-1"
}

variable "rds_user" {
  description = "The username for the RDS database (used in prod only)."
  type        = string
  default     = "ticketly"
}

variable "rds_password" {
  description = "The password for the RDS database (used in prod only)."
  type        = string
  sensitive   = true
}