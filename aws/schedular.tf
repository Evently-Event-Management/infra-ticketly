resource "aws_scheduler_schedule" "trending_events_daily_job" {
  name       = "trending-events-daily-job-${terraform.workspace}"
  group_name = aws_scheduler_schedule_group.ticketly.name

  flexible_time_window {
    mode = "OFF"
  }

  # Run every 6 hours
  schedule_expression          = "cron(0 0/6 * * ? *)"
  schedule_expression_timezone = "Asia/Colombo"

  target {
    arn      = aws_sqs_queue.trending_job.arn
    role_arn = aws_iam_role.eventbridge_scheduler_role.arn

    input = jsonencode({
      "jobType" : "CALCULATE_TRENDING_EVENTS",
      "timestamp" : formatdate("YYYY-MM-DD'T'hh:mm:ssZ", timestamp())
    })
  }

  depends_on = [
    aws_scheduler_schedule_group.ticketly,
    aws_sqs_queue.trending_job,
    aws_iam_role_policy_attachment.scheduler_attach
  ]
}
