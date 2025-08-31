resource "aws_db_subnet_group" "ticketly" {
  name       = "ticketly-db-subnets"
  subnet_ids = aws_subnet.private[*].id
}

resource "aws_db_instance" "ticketly_db" {
  identifier = "ticketly-db"
  engine     = "postgres"
  engine_version = "17"
  instance_class = "db.t3.micro"
  username  = var.rds_user
  password  = var.rds_password
  allocated_storage = 20
  db_subnet_group_name = aws_db_subnet_group.ticketly.name
  vpc_security_group_ids = [aws_security_group.database.id]
  publicly_accessible = true # For development access
  skip_final_snapshot = true
  
  # Free tier optimization
  storage_type = "gp2"
  max_allocated_storage = 0 # Disable autoscaling to keep within free tier
  
  tags = {
    Name = "ticketly-db"
    Environment = "development"
  }
}
