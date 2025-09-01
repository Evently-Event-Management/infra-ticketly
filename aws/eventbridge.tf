resource "aws_scheduler_schedule_group" "ticketly" {
  name = "event-ticketing-schedules"
  
  tags = {
    Name = "ticketly-schedules"
    Environment = "development"
  }
}