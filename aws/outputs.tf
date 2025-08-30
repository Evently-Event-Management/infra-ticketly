output "ticketly_dev_user_access_key" {
  value = aws_iam_access_key.ticketly_dev_user_key.id
}

output "ticketly_dev_user_secret_key" {
  value = aws_iam_access_key.ticketly_dev_user_key.secret
  sensitive = true
}

output "keycloak_db_endpoint" {
  value = aws_db_instance.ticketly_db.endpoint
}

output "sqs_session_on_sale_url" {
  value = aws_sqs_queue.session_on_sale.url
}
