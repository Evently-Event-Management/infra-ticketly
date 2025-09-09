output "aws_region" {
  value = var.aws_region
}

output "ticketly_dev_user_access_key" {
  value = aws_iam_access_key.ticketly_dev_user_key.id
}

output "ticketly_dev_user_secret_key" {
  value = aws_iam_access_key.ticketly_dev_user_key.secret
  sensitive = true
}

output "s3_bucket_name" {
  value = aws_s3_bucket.ticketly_assets.id
}

output "sqs_session_on_sale_url" {
  value = aws_sqs_queue.session_on_sale.url
}

output "sqs_session_on_sale_arn" {
  value = aws_sqs_queue.session_on_sale.arn
}

output "sqs_session_closed_url" {
  value = aws_sqs_queue.session_closed.url
}

output "sqs_session_closed_arn" {
  value = aws_sqs_queue.session_closed.arn
}

output "scheduler_role_arn" {
  value = aws_iam_role.eventbridge_scheduler_role.arn
}

output "scheduler_group_name" {
  value = aws_scheduler_schedule_group.ticketly.name
}