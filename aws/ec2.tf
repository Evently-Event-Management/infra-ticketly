resource "aws_instance" "ticketly-infra" {
  ami                    = "ami-0360c520857e3138f" # Ubuntu 24.04 LTS
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public[0].id
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.public.id]

  key_name               = aws_key_pair.ticketly.key_name

  depends_on = [aws_key_pair.ticketly]

  user_data = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y docker.io docker-compose
    systemctl enable docker
    systemctl start docker
    echo "Docker installed successfully"
  EOF

  tags = {
    Name = "ticketly-infra"
  }
}