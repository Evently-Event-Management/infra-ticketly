output "aws_region" {
  value = var.aws_region
}

output "s3_bucket_name" {
  description = "The name of the S3 bucket for storing assets."
  value       = aws_s3_bucket.ticketly_assets.id
}

output "sqs_session_on_sale_url" {
  description = "The URL of the SQS queue for 'session on sale' events."
  value       = aws_sqs_queue.session_on_sale.url
}

output "sqs_session_on_sale_arn" {
  description = "The ARN of the SQS queue for 'session on sale' events."
  value       = aws_sqs_queue.session_on_sale.arn
}

output "sqs_session_closed_url" {
  description = "The URL of the SQS queue for 'session closed' events."
  value       = aws_sqs_queue.session_closed.url
}

output "sqs_session_closed_arn" {
  description = "The ARN of the SQS queue for 'session closed' events."
  value       = aws_sqs_queue.session_closed.arn
}

output "scheduler_role_arn" {
  description = "The ARN of the IAM role for the EventBridge Scheduler."
  value       = aws_iam_role.eventbridge_scheduler_role.arn
}

output "scheduler_group_name" {
  description = "The name of the EventBridge Scheduler group."
  value       = aws_scheduler_schedule_group.ticketly.name
}

output "service_user_access_key" {
  description = "Access key for service user."
  value       = aws_iam_access_key.ticketly_service_user_key.id
  sensitive   = true
}

output "service_user_secret_key" {
  description = "Secret key for service user."
  value       = aws_iam_access_key.ticketly_service_user_key.secret
  sensitive   = true
}

# --- Production-Only Outputs ---

output "ticketly_db_endpoint" {
  description = "The connection endpoint for the RDS instance. (Prod only)"
  value       = local.is_prod ? aws_db_instance.ticketly_db[0].endpoint : "N/A (not deployed in this workspace)"
}
output "ticketly_db_address" {
  value = local.is_prod ? aws_db_instance.ticketly_db[0].address : "N/A (not deployed in this workspace)"
}

output "ticketly_db_port" {
  value = local.is_prod ? aws_db_instance.ticketly_db[0].port : "N/A (not deployed in this workspace)"
}

output "ticketly_db_user" {
  value = local.is_prod ? aws_db_instance.ticketly_db[0].username : "N/A (not deployed in this workspace)"
}

output "ticketly_db_password" {
  value     = local.is_prod ? aws_db_instance.ticketly_db[0].password : "N/A (not deployed in this workspace)"
  sensitive = true
}

output "ec2_ip" {
  description = "The public IP address of the EC2 instance. (Prod only)"
  value       = local.is_prod ? aws_instance.ticketly-infra[0].public_ip : "N/A (not deployed in this workspace)"
}