# EC2 instance is only created in the 'prod' workspace.
resource "aws_instance" "ticketly-infra" {
  count = local.is_prod ? 1 : 0

  ami                    = "ami-02d26659fd82cf299" # Ubuntu 24.04 LTS
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public[0].id
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.public[0].id]
  key_name               = aws_key_pair.ticketly[0].key_name

  tags = { Name = "ticketly-infra" }
}

# Key pair is only needed for the EC2 instance in 'prod'.
resource "aws_key_pair" "ticketly" {
  count = local.is_prod ? 1 : 0

  key_name   = "ticketly-key"
  public_key = var.public_key_content
}