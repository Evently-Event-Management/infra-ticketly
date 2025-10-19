resource "aws_db_subnet_group" "ticketly" {
  name       = "ticketly-db-subnets"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "ticketly-db-subnet-group"
    VPC  = aws_vpc.ticketly_vpc.id
  }
}

resource "aws_db_parameter_group" "ticketly_logical_replication" {
  name   = "ticketly-logical-replication"
  family = "postgres16"

  parameter {
    name         = "rds.logical_replication"
    value        = "1"
    apply_method = "pending-reboot"
  }
}

resource "aws_db_instance" "ticketly_db" {
  identifier             = "ticketly-db"
  engine                 = "postgres"
  engine_version         = "16.8"
  instance_class         = "db.t3.micro"
  username               = var.rds_user
  password               = var.rds_password
  allocated_storage      = 20
  parameter_group_name   = aws_db_parameter_group.ticketly_logical_replication.name
  vpc_security_group_ids = [aws_security_group.database.id]
  db_subnet_group_name   = aws_db_subnet_group.ticketly.name
  publicly_accessible    = true
  skip_final_snapshot    = true

  tags = {
    Name        = "ticketly-db"
    Environment = "production"
    VPC         = aws_vpc.ticketly_vpc.id
  }
}
