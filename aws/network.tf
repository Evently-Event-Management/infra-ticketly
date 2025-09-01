data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "ticketly_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true
  
  tags = {
    Name = "ticketly-vpc"
  }
}

# Public Subnets
resource "aws_subnet" "public" {
  count             = 3
  vpc_id            = aws_vpc.ticketly_vpc.id
  cidr_block        = cidrsubnet(aws_vpc.ticketly_vpc.cidr_block, 4, count.index)
  map_public_ip_on_launch = true
  availability_zone = data.aws_availability_zones.available.names[count.index]
}

# Private Subnets
resource "aws_subnet" "private" {
  count             = 3
  vpc_id            = aws_vpc.ticketly_vpc.id
  cidr_block        = cidrsubnet(aws_vpc.ticketly_vpc.cidr_block, 4, count.index + 3)
  availability_zone = data.aws_availability_zones.available.names[count.index]
}
