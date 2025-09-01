resource "aws_db_subnet_group" "ticketly" {
  name       = "ticketly-db-subnets"
  subnet_ids = aws_subnet.private[*].id
}

resource "aws_db_parameter_group" "ticketly_logical_replication" {
  name   = "ticketly-logical-replication"
  family = "postgres17"

  parameter {
    name         = "rds.logical_replication"
    value        = "1"
    apply_method = "pending-reboot"
  }

  tags = {
    Name = "TicketlyLogicalReplication"
  }
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
  parameter_group_name = aws_db_parameter_group.ticketly_logical_replication.name
  vpc_security_group_ids = [aws_security_group.database.id]
  publicly_accessible = true # For development access
  skip_final_snapshot = true
  apply_immediately = true

  # Free tier optimization
  storage_type = "gp2"
  max_allocated_storage = 0 # Disable autoscaling to keep within free tier
  
  tags = {
    Name = "ticketly-db"
    Environment = "development"
  }
}
