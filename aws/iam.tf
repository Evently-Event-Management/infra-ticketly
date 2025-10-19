resource "aws_iam_user" "ticketly_service_user" {
  name = "ticketly-service-user-${terraform.workspace}"
}

resource "aws_iam_access_key" "ticketly_service_user_key" {
  user = aws_iam_user.ticketly_service_user.name
}

# S3 Policy
resource "aws_iam_policy" "ticketly_s3_policy" {
  name        = "TicketlyS3AccessPolicy"
  description = "Access to S3 bucket for Ticketly"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:PutObjectAcl"
        ],
        Resource = "${aws_s3_bucket.ticketly_assets.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket.ticketly_assets]
}

resource "aws_iam_user_policy_attachment" "ticketly_s3_attach" {
  user       = aws_iam_user.ticketly_service_user.name
  policy_arn = aws_iam_policy.ticketly_s3_policy.arn

  depends_on = [aws_iam_policy.ticketly_s3_policy, aws_iam_user.ticketly_service_user]
}

# SQS Consumer Policy
resource "aws_iam_policy" "ticketly_sqs_consumer_policy" {
  name        = "TicketlyAppSqsConsumerPolicy"
  description = "Access to SQS for Ticketly"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage"
        ],
        Resource = [
          aws_sqs_queue.session_scheduling.arn,
          aws_sqs_queue.trending_job.arn,
          aws_sqs_queue.session_reminders.arn
        ]
      }
    ]
  })

  depends_on = [aws_sqs_queue.session_scheduling, aws_sqs_queue.trending_job, aws_sqs_queue.session_reminders]
}

resource "aws_iam_user_policy_attachment" "ticketly_sqs_attach" {
  user       = aws_iam_user.ticketly_service_user.name
  policy_arn = aws_iam_policy.ticketly_sqs_consumer_policy.arn

  depends_on = [aws_iam_policy.ticketly_sqs_consumer_policy, aws_iam_user.ticketly_service_user]
}

# EventBridge Schedule policy
resource "aws_iam_policy" "ticketly_eventbridge_schedule_policy" {
  name        = "TicketlyAppEventBridgeSchedulePolicy"
  description = "Access to EventBridge for Ticketly"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "scheduler:CreateSchedule",
          "scheduler:UpdateSchedule",
          "scheduler:DeleteSchedule"
        ]
        Resource = "${replace(aws_scheduler_schedule_group.ticketly.arn, "schedule-group", "schedule")}/*"
      },
      {
        Effect   = "Allow",
        Action   = "iam:PassRole",
        Resource = aws_iam_role.eventbridge_scheduler_role.arn
      }
    ]
  })

  depends_on = [aws_scheduler_schedule_group.ticketly, aws_iam_role.eventbridge_scheduler_role]
}

resource "aws_iam_user_policy_attachment" "ticketly_eventbridge_schedule_attach" {
  user       = aws_iam_user.ticketly_service_user.name
  policy_arn = aws_iam_policy.ticketly_eventbridge_schedule_policy.arn

  depends_on = [aws_iam_policy.ticketly_eventbridge_schedule_policy, aws_iam_user.ticketly_service_user]
}

# EventBridge Scheduler Role - Trust relationship
resource "aws_iam_role" "eventbridge_scheduler_role" {
  name = "EventBridgeSchedulerSqsRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "scheduler.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Policy that allows EventBridge Scheduler to send messages to SQS
resource "aws_iam_policy" "allow_scheduler_to_send_sqs" {
  name = "AllowSchedulerToSendToSqsPolicy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = "sqs:SendMessage",
        Resource = [
          aws_sqs_queue.session_scheduling.arn,
          aws_sqs_queue.trending_job.arn,
          aws_sqs_queue.session_reminders.arn
        ]
      }
    ]
  })

  depends_on = [aws_sqs_queue.session_scheduling, aws_sqs_queue.trending_job, aws_sqs_queue.session_reminders]
}

resource "aws_iam_role_policy_attachment" "scheduler_attach" {
  role       = aws_iam_role.eventbridge_scheduler_role.name
  policy_arn = aws_iam_policy.allow_scheduler_to_send_sqs.arn

  depends_on = [aws_iam_policy.allow_scheduler_to_send_sqs, aws_iam_role.eventbridge_scheduler_role]
}

# IAM role and instance profile to enable SSM access to EC2 instances.
resource "aws_iam_role" "ec2_ssm_role" {
  name = "ticketly-ec2-ssm-role-${terraform.workspace}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_ssm_managed_policy" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_ssm" {
  name = "ticketly-ec2-ssm-profile-${terraform.workspace}"
  role = aws_iam_role.ec2_ssm_role.name
}
