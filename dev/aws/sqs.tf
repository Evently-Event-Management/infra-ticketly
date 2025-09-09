resource "aws_sqs_queue" "session_on_sale" {
  name = "session-on-sale-queue"
  
  tags = {
    Name = "ticketly-session-on-sale"
    Environment = "development"
  }
}

resource "aws_sqs_queue" "session_closed" {
  name = "session-closed-queue"
  
  tags = {
    Name = "ticketly-session-closed"
    Environment = "development"
  }
}
