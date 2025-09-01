resource "aws_instance" "ticketly-infra" {
  ami                    = "ami-02d26659fd82cf299" # Ubuntu 24.04 LTS
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public[0].id
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.public.id]

  key_name               = aws_key_pair.ticketly.key_name

  depends_on = [aws_key_pair.ticketly]

  tags = {
    Name = "ticketly-infra"
  }
}