resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.ticketly_vpc.id
  
  tags = {
    Name = "ticketly-igw"
  }
}

# Route table for public subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.ticketly_vpc.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  
  tags = {
    Name = "ticketly-public-rt"
  }
}

# Associate public subnets with public route table
resource "aws_route_table_association" "public" {
  count          = 3
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Route table for private subnets
# Note: We're not adding a NAT Gateway since our RDS doesn't need outbound internet access
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.ticketly_vpc.id
  
  # No internet route needed for now
  # If later services need internet access, you can add a NAT Gateway

  # igw access for development
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "ticketly-private-rt"
  }
}

# Associate private subnets with private route table
resource "aws_route_table_association" "private" {
  count          = 3
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
