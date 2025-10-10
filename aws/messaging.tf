resource "aws_sqs_queue" "session_scheduling" {
  name = "session-scheduling-queue-${terraform.workspace}"
  tags = {
    Name        = "ticketly-session-scheduling"
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

resource "aws_sqs_queue" "trending_job" {
  name = "trending-job-queue-${terraform.workspace}"
  tags = {
    Name        = "ticketly-trending-job"
    Environment = terraform.workspace
  }
}