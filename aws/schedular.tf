resource "aws_scheduler_schedule" "trending_events_daily_job" {
  name       = "trending-events-daily-job-${terraform.workspace}"
  group_name = aws_scheduler_schedule_group.ticketly.name

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression          = "cron(0 * * * ? *)"
  schedule_expression_timezone = "Asia/Colombo"

  # --- THIS IS THE CHANGE ---
  # Update the target to point to the new queue's ARN.
  target {
    arn      = aws_sqs_queue.trending_job.arn # Point to the new queue
    role_arn = aws_iam_role.eventbridge_scheduler_role.arn

    input = jsonencode({
      "jobType" : "CALCULATE_TRENDING_EVENTS",
      "timestamp" : formatdate("YYYY-MM-DD'T'hh:mm:ssZ", timestamp())
    })
  }
  # --- END OF CHANGE ---

  depends_on = [
    aws_scheduler_schedule_group.ticketly,
    aws_sqs_queue.trending_job, # Depend on the new queue
    aws_iam_role_policy_attachment.scheduler_attach
  ]
}
