# network.tf (UPDATED)
# All resources in this file are now created ONLY in the 'prod' workspace.

data "aws_availability_zones" "available" {}

resource "aws_vpc" "ticketly_vpc" {
  count = local.is_prod ? 1 : 0

  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = { Name = "ticketly-vpc-${terraform.workspace}" }
}

resource "aws_internet_gateway" "igw" {
  count = local.is_prod ? 1 : 0

  vpc_id = aws_vpc.ticketly_vpc[0].id
  tags   = { Name = "ticketly-igw-${terraform.workspace}" }
}

resource "aws_subnet" "public" {
  count = local.is_prod ? 3 : 0 # Create 3 subnets for prod, 0 for dev

  vpc_id                  = aws_vpc.ticketly_vpc[0].id
  cidr_block              = cidrsubnet(aws_vpc.ticketly_vpc[0].cidr_block, 4, count.index)
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  tags                    = { Name = "ticketly-public-subnet-${count.index}-${terraform.workspace}" }
}

resource "aws_subnet" "private" {
  count = local.is_prod ? 3 : 0 # Create 3 subnets for prod, 0 for dev

  vpc_id            = aws_vpc.ticketly_vpc[0].id
  cidr_block        = cidrsubnet(aws_vpc.ticketly_vpc[0].cidr_block, 4, count.index + 3)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags              = { Name = "ticketly-private-subnet-${count.index}-${terraform.workspace}" }
}

# All networking resources below are also made conditional
resource "aws_route_table" "public" {
  count = local.is_prod ? 1 : 0

  vpc_id = aws_vpc.ticketly_vpc[0].id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw[0].id
  }
  tags = { Name = "ticketly-public-rt-${terraform.workspace}" }
}

resource "aws_route_table_association" "public" {
  count = local.is_prod ? 3 : 0

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id
}

resource "aws_security_group" "public" {
  count = local.is_prod ? 1 : 0

  name        = "ticketly-public-sg-${terraform.workspace}"
  description = "Security group for public instances"
  vpc_id      = aws_vpc.ticketly_vpc[0].id
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }
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
  }
  tags = { Name = "ticketly-public-sg-${terraform.workspace}" }
}

resource "aws_security_group" "database" {
  count = local.is_prod ? 1 : 0

  name        = "ticketly-database-sg-${terraform.workspace}"
  description = "Security group for database instances"
  vpc_id      = aws_vpc.ticketly_vpc[0].id
  
  # Note: The reference to the public security group also needs the index [0]
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.public[0].id]
    description     = "PostgreSQL access from application"
  }
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
  }
  tags = { Name = "ticketly-database-sg-${terraform.workspace}" }
}