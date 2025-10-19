output "aws_region" {
  value = var.aws_region
}

output "s3_bucket_name" {
  description = "The name of the S3 bucket for storing assets."
  value       = aws_s3_bucket.ticketly_assets.id
}

output "sqs_session_scheduling_url" {
  description = "The URL of the SQS queue for 'session scheduling' events."
  value       = aws_sqs_queue.session_scheduling.url
}

output "sqs_session_scheduling_arn" {
  description = "The ARN of the SQS queue for 'session scheduling' events."
  value       = aws_sqs_queue.session_scheduling.arn
}

output "sqs_trending_job_url" {
  description = "The URL of the SQS queue for 'trending job' events."
  value       = aws_sqs_queue.trending_job.url
}

output "sqs_trending_job_arn" {
  description = "The ARN of the SQS queue for 'trending job' events."
  value       = aws_sqs_queue.trending_job.arn
}

output "sqs_session_reminders_url" {
  description = "The URL of the SQS queue for 'session reminders' events."
  value       = aws_sqs_queue.session_reminders.url
}

output "sqs_session_reminders_arn" {
  description = "The ARN of the SQS queue for 'session reminders' events."
  value       = aws_sqs_queue.session_reminders.arn
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

output "ticketly_db_endpoint" {
  description = "The connection endpoint for the RDS instance."
  value       = aws_db_instance.ticketly_db.endpoint
}

output "ticketly_db_address" {
  value = aws_db_instance.ticketly_db.address
}

output "ticketly_db_port" {
  value = aws_db_instance.ticketly_db.port
}

output "ticketly_db_user" {
  value = aws_db_instance.ticketly_db.username
}

output "ticketly_db_password" {
  value     = aws_db_instance.ticketly_db.password
  sensitive = true
}

output "auth_public_ip" {
  description = "Public IP address of the Keycloak auth server."
  value       = aws_instance.ticketly_auth.public_ip
}

output "auth_ssh_command" {
  description = "SSH command for the Keycloak auth server."
  value       = "ssh -i ${path.module}/ticketly-key ubuntu@${aws_instance.ticketly_auth.public_ip}"
}

output "control_plane_public_ip" {
  description = "Public IP address of the Kubernetes control plane node."
  value       = aws_instance.control_plane.public_ip
}

output "control_plane_ssh_command" {
  description = "SSH command for the control plane node."
  value       = "ssh -i ${path.module}/ticketly-key ubuntu@${aws_instance.control_plane.public_ip}"
}

output "worker_private_ips" {
  description = "Private IP addresses for the Kubernetes worker nodes."
  value       = [for worker in values(aws_instance.worker) : worker.private_ip]
}

output "infra_private_ip" {
  description = "Private IP address for the infrastructure services node."
  value       = aws_instance.infra.private_ip
}
