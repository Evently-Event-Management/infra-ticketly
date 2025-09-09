resource "aws_sqs_queue" "session_on_sale" {
  name = "session-on-sale-queue-${terraform.workspace}"
  tags = {
    Name        = "ticketly-session-on-sale"
    Environment = terraform.workspace
  }
}

resource "aws_sqs_queue" "session_closed" {
  name = "session-closed-queue-${terraform.workspace}"
  tags = {
    Name        = "ticketly-session-closed"
    Environment = terraform.workspace
  }
}

resource "aws_scheduler_schedule_group" "ticketly" {
  name = "event-ticketing-schedules-${terraform.workspace}"
  tags = {
    Name        = "ticketly-schedules"
    Environment = terraform.workspace
  }
}