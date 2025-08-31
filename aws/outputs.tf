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

output "ec2_ip" {
  value = aws_instance.ticketly-infra.public_ip
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