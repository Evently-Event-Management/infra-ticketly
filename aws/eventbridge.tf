resource "aws_scheduler_schedule_group" "ticketly" {
  name = "event-ticketing-schedules"
  
  tags = {
    Name = "ticketly-schedules"
    Environment = "development"
  }
}

resource "aws_scheduler_schedule" "session_on_sale_schedule" {
  name      = "session-on-sale"
  group_name = aws_scheduler_schedule_group.ticketly.name
  schedule_expression = "rate(1 hour)"
  
  target {
    arn = aws_sqs_queue.session_on_sale.arn
    role_arn = aws_iam_role.eventbridge_scheduler_role.arn
  }

  flexible_time_window {
    mode = "OFF"
  }
  
  depends_on = [
    aws_scheduler_schedule_group.ticketly,
    aws_sqs_queue.session_on_sale,
    aws_iam_role.eventbridge_scheduler_role,
    aws_iam_role_policy_attachment.scheduler_attach
  ]
}

resource "aws_scheduler_schedule" "session_closed_schedule" {
  name      = "session-closed"
  group_name = aws_scheduler_schedule_group.ticketly.name
  schedule_expression = "rate(1 hour)"
  
  target {
    arn = aws_sqs_queue.session_closed.arn
    role_arn = aws_iam_role.eventbridge_scheduler_role.arn
  }

  flexible_time_window {
    mode = "OFF"
  }
  
  depends_on = [
    aws_scheduler_schedule_group.ticketly,
    aws_sqs_queue.session_closed,
    aws_iam_role.eventbridge_scheduler_role,
    aws_iam_role_policy_attachment.scheduler_attach
  ]
}
