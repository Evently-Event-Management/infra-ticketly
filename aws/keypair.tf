resource "aws_key_pair" "ticketly" {
  key_name   = "ticketly-key"
  public_key = var.public_key_content
}