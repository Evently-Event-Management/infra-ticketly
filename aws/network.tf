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

# Elastic IP for NAT gateway - provisioned only when prod workspace is active.
resource "aws_eip" "nat" {
  count = local.is_prod ? 1 : 0

  domain     = "vpc"
  depends_on = [aws_internet_gateway.igw]

  tags = { Name = "ticketly-nat-eip-${terraform.workspace}" }
}

# NAT gateway providing egress for private subnets in prod.
resource "aws_nat_gateway" "public" {
  count = local.is_prod ? 1 : 0

  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id

  tags = { Name = "ticketly-nat-${terraform.workspace}" }
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



# Route table for private subnets (for now with IGW)
resource "aws_route_table" "private" {
  count = local.is_prod ? 1 : 0

  vpc_id = aws_vpc.ticketly_vpc[0].id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.public[0].id
  }

  tags = { Name = "ticketly-private-rt-${terraform.workspace}" }
}

# Associate private subnets with private route table
resource "aws_route_table_association" "private" {
  count          = local.is_prod ? 3 : 0
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[0].id
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
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["112.135.195.95/32"]
    description = "Kubernetes API access from Home IP"
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

  ingress {
    from_port   = 8472
    to_port     = 8472
    protocol    = "udp"
    cidr_blocks = ["10.0.0.0/16"]
    description = "Flannel VXLAN from workers"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "ticketly-public-sg-${terraform.workspace}" }
}

# Security group for the external application load balancer.
resource "aws_security_group" "alb" {
  count = local.is_prod ? 1 : 0

  name        = "ticketly-alb-sg-${terraform.workspace}"
  description = "Security group for the public Application Load Balancer"
  vpc_id      = aws_vpc.ticketly_vpc[0].id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP access"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS access"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "ticketly-alb-sg-${terraform.workspace}" }
}

# Security group for private worker nodes.
resource "aws_security_group" "worker" {
  count = local.is_prod ? 1 : 0

  name        = "ticketly-worker-sg-${terraform.workspace}"
  description = "Security group for Kubernetes worker nodes"
  vpc_id      = aws_vpc.ticketly_vpc[0].id

  # Kubelet API
  ingress {
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    self        = true
    description = "Kubelet API"
  }

  # NodePort Services
  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Kubernetes NodePort Services"
  }
  
  
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.public[0].id]
    description     = "SSH access from control plane"
  }

  ingress {
    from_port   = 8472
    to_port     = 8472
    protocol    = "udp"
    cidr_blocks = ["10.0.0.0/16"]
    description = "Flannel VXLAN from control plane"
  }

  ingress {
    from_port   = 8472
    to_port     = 8472
    protocol    = "udp"
    self        = true
    description = "Flannel VXLAN from other workers"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "ticketly-worker-sg-${terraform.workspace}" }
}

# Security group for internal infrastructure services host.
resource "aws_security_group" "infra" {
  count = local.is_prod ? 1 : 0

  name        = "ticketly-infra-sg-${terraform.workspace}"
  description = "Security group for shared infrastructure services"
  vpc_id      = aws_vpc.ticketly_vpc[0].id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH access from control plane
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.public[0].id]
    description     = "SSH access from control plane"
  }

  tags = { Name = "ticketly-infra-sg-${terraform.workspace}" }
}

# Allow traffic from worker nodes to infrastructure services.
resource "aws_security_group_rule" "infra_from_workers" {
  count = local.is_prod ? 1 : 0

  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.infra[0].id
  source_security_group_id = aws_security_group.worker[0].id
  description              = "Allow worker nodes to reach infra host"
}

# Allow all traffic from the control plane to worker nodes.
resource "aws_security_group_rule" "workers_from_control_plane" {
  count = local.is_prod ? 1 : 0

  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.worker[0].id
  source_security_group_id = aws_security_group.public[0].id
  description              = "Allow control plane to reach worker nodes"
}

# Allow HTTP traffic from the ALB to worker nodes.
resource "aws_security_group_rule" "workers_from_alb" {
  count = local.is_prod ? 1 : 0

  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.worker[0].id
  source_security_group_id = aws_security_group.alb[0].id
  description              = "Allow ALB to forward web traffic to workers"
}

# Allow Kubernetes API traffic from worker nodes to the control plane.
resource "aws_security_group_rule" "control_plane_from_workers" {
  count = local.is_prod ? 1 : 0

  type                     = "ingress"
  from_port                = 6443
  to_port                  = 6443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.public[0].id
  source_security_group_id = aws_security_group.worker[0].id
  description              = "Allow worker nodes to reach the control plane API"
}

# Allow traffic from control plane to worker nodes on port 8443 for dashboard
resource "aws_security_group_rule" "dashboard_from_control_plane" {
  count = local.is_prod ? 1 : 0

  type                     = "ingress"
  from_port                = 8443
  to_port                  = 8443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.worker[0].id
  source_security_group_id = aws_security_group.public[0].id
  description              = "Allow control plane to reach Kubernetes dashboard"
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