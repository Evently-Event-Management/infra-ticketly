output "ticketly_dev_user_access_key" {
  value = aws_iam_access_key.ticketly_dev_user_key.id
}

output "ticketly_dev_user_secret_key" {
  value = aws_iam_access_key.ticketly_dev_user_key.secret
  sensitive = true
}

output "ticketly_db_endpoint" {
  value = aws_db_instance.ticketly_db.endpoint
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

output "ec2_ip" {
  value = aws_instance.ticketly-infra.public_ip
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

