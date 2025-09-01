## Security Groups

# Security group for public instances (EC2)
resource "aws_security_group" "public" {
  name        = "ticketly-public-sg"
  description = "Security group for public instances"
  vpc_id      = aws_vpc.ticketly_vpc.id

  # SSH access from anywhere (for development)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP access"
  }

  # HTTPS access from anywhere
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS access"
  }

  # Custom application ports
  ingress {
    from_port   = 8080
    to_port     = 8088
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Application ports"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "ticketly-public-sg"
  }
}

# Security group for database (RDS)
resource "aws_security_group" "database" {
  name        = "ticketly-database-sg"
  description = "Security group for database instances"
  vpc_id      = aws_vpc.ticketly_vpc.id

  # PostgreSQL access from public security group
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.public.id]
    description     = "PostgreSQL access from application"
  }

  # For development, allow direct access from anywhere (remove in production)
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "PostgreSQL direct access for development"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "ticketly-database-sg"
  }
}
