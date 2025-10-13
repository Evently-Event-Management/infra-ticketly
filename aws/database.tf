# The entire RDS setup is only created in the 'prod' workspace.
resource "aws_db_subnet_group" "ticketly" {
  count = local.is_prod ? 1 : 0

  name       = "ticketly-db-subnets"
  subnet_ids = aws_subnet.private[*].id
}

resource "aws_db_parameter_group" "ticketly_logical_replication" {
  count = local.is_prod ? 1 : 0

  name   = "ticketly-logical-replication"
  family = "postgres16"

  parameter {
    name         = "rds.logical_replication"
    value        = "1"
    apply_method = "pending-reboot"
  }
}


resource "aws_db_instance" "ticketly_db" {
  count = local.is_prod ? 1 : 0

  identifier           = "ticketly-db"
  engine               = "postgres"
  engine_version       = "16.3"
  instance_class       = "db.t3.micro"
  username             = var.rds_user
  password             = var.rds_password
  allocated_storage    = 20
  parameter_group_name = aws_db_parameter_group.ticketly_logical_replication[0].name
  vpc_security_group_ids = [aws_security_group.database[0].id]
  publicly_accessible  = true
  skip_final_snapshot  = true

  tags = {
    Name        = "ticketly-db"
    Environment = "production"
  }
}