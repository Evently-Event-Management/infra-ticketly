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