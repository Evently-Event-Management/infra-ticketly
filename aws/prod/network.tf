data "aws_availability_zones" "available" {}

resource "aws_vpc" "ticketly_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = { Name = "ticketly-vpc-${terraform.workspace}" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.ticketly_vpc.id
  tags   = { Name = "ticketly-igw-${terraform.workspace}" }
}

resource "aws_eip" "nat" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.igw]
  tags       = { Name = "ticketly-nat-eip-${terraform.workspace}" }
}

resource "aws_nat_gateway" "public" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id
  tags          = { Name = "ticketly-nat-${terraform.workspace}" }
}

resource "aws_subnet" "public" {
  count = 3

  vpc_id                  = aws_vpc.ticketly_vpc.id
  cidr_block              = cidrsubnet(aws_vpc.ticketly_vpc.cidr_block, 4, count.index)
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  tags                    = { Name = "ticketly-public-subnet-${count.index}-${terraform.workspace}" }
}

resource "aws_subnet" "private" {
  count = 3

  vpc_id            = aws_vpc.ticketly_vpc.id
  cidr_block        = cidrsubnet(aws_vpc.ticketly_vpc.cidr_block, 4, count.index + 3)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags              = { Name = "ticketly-private-subnet-${count.index}-${terraform.workspace}" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.ticketly_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = { Name = "ticketly-public-rt-${terraform.workspace}" }
}

resource "aws_route_table_association" "public" {
  count = 3

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.ticketly_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.public.id
  }

  tags = { Name = "ticketly-private-rt-${terraform.workspace}" }
}

resource "aws_route_table_association" "private" {
  count = 3

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# --- SECURITY GROUPS (Empty) ---

resource "aws_security_group" "public" {
  name        = "ticketly-public-sg-${terraform.workspace}"
  description = "Security group for public instances"
  vpc_id      = aws_vpc.ticketly_vpc.id

  # All ingress rules are defined separately below
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "ticketly-public-sg-${terraform.workspace}" }
}

resource "aws_security_group" "alb" {
  name        = "ticketly-alb-sg-${terraform.workspace}"
  description = "Security group for the public Application Load Balancer"
  vpc_id      = aws_vpc.ticketly_vpc.id

  # All ingress rules are defined separately below
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "ticketly-alb-sg-${terraform.workspace}" }
}

resource "aws_security_group" "worker" {
  name        = "ticketly-worker-sg-${terraform.workspace}"
  description = "Security group for Kubernetes worker nodes"
  vpc_id      = aws_vpc.ticketly_vpc.id

  # All ingress rules are defined separately below
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "ticketly-worker-sg-${terraform.workspace}" }
}

resource "aws_security_group" "infra" {
  name        = "ticketly-infra-sg-${terraform.workspace}"
  description = "Security group for shared infrastructure services"
  vpc_id      = aws_vpc.ticketly_vpc.id

  # All ingress rules are defined separately below
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "ticketly-infra-sg-${terraform.workspace}" }
}

resource "aws_security_group" "database" {
  name        = "ticketly-database-sg-${terraform.workspace}"
  description = "Security group for database instances"
  vpc_id      = aws_vpc.ticketly_vpc.id

  # All ingress rules are defined separately below
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "ticketly-database-sg-${terraform.workspace}" }
}

# --- STANDALONE SECURITY GROUP RULES ---

# --- ALB Rules (aws_security_group.alb) ---
resource "aws_security_group_rule" "alb_http_in" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
  description       = "HTTP access"
}

resource "aws_security_group_rule" "alb_https_in" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
  description       = "HTTPS access"
}

# --- Public Rules (aws_security_group.public) ---
resource "aws_security_group_rule" "public_ssh_in" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.public.id
  description       = "SSH access"
}

resource "aws_security_group_rule" "public_app_ports_in" {
  type              = "ingress"
  from_port         = 8080
  to_port           = 8088
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.public.id
  description       = "Application ports"
}

resource "aws_security_group_rule" "public_kube_api_from_home_in" {
  type              = "ingress"
  from_port         = 6443
  to_port           = 6443
  protocol          = "tcp"
  cidr_blocks       = ["${var.my_ip}/32"]
  security_group_id = aws_security_group.public.id
  description       = "Kubernetes API access from Home IP"
}

resource "aws_security_group_rule" "public_kube_api_from_everywhere" {
  type              = "ingress"
  from_port         = 6443
  to_port           = 6443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.public.id
  description       = "Kubernetes API access from Everywhere"
}

resource "aws_security_group_rule" "public_http_in_generic" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.public.id
  description       = "HTTP access"
}

resource "aws_security_group_rule" "public_https_in_generic" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.public.id
  description       = "HTTPS access"
}

resource "aws_security_group_rule" "public_flannel_from_workers_in" {
  type                     = "ingress"
  from_port                = 8472
  to_port                  = 8472
  protocol                 = "udp"
  source_security_group_id = aws_security_group.worker.id
  security_group_id        = aws_security_group.public.id
  description              = "Flannel VXLAN from workers"
}

resource "aws_security_group_rule" "public_flannel_from_self_in" {
  type              = "ingress"
  from_port         = 8472
  to_port           = 8472
  protocol          = "udp"
  self              = true
  security_group_id = aws_security_group.public.id
  description       = "Flannel VXLAN from self"
}

resource "aws_security_group_rule" "public_kubelet_from_self_in" {
  type              = "ingress"
  from_port         = 10250
  to_port           = 10250
  protocol          = "tcp"
  self              = true
  security_group_id = aws_security_group.public.id
  description       = "Kubelet API from self"
}

resource "aws_security_group_rule" "public_kubelet_from_workers_in" {
  type                     = "ingress"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.worker.id
  security_group_id        = aws_security_group.public.id
  description              = "Kubelet API from workers"
}

# --- Worker Rules (aws_security_group.worker) ---
resource "aws_security_group_rule" "worker_kubelet_from_public_in" {
  type                     = "ingress"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.public.id
  security_group_id        = aws_security_group.worker.id
  description              = "Kubelet API from control plane"
}

resource "aws_security_group_rule" "worker_kubelet_from_self_in" {
  type              = "ingress"
  from_port         = 10250
  to_port           = 10250
  protocol          = "tcp"
  self              = true
  security_group_id = aws_security_group.worker.id
  description       = "Kubelet API from other workers"
}

resource "aws_security_group_rule" "worker_nodeports_in" {
  type              = "ingress"
  from_port         = 30000
  to_port           = 32767
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.worker.id
  description       = "Kubernetes NodePort Services"
}

resource "aws_security_group_rule" "worker_ssh_from_public_in" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.public.id
  security_group_id        = aws_security_group.worker.id
  description              = "SSH access from control plane"
}

resource "aws_security_group_rule" "worker_flannel_from_public_in" {
  type                     = "ingress"
  from_port                = 8472
  to_port                  = 8472
  protocol                 = "udp"
  source_security_group_id = aws_security_group.public.id
  security_group_id        = aws_security_group.worker.id
  description              = "Flannel VXLAN from control plane"
}

resource "aws_security_group_rule" "worker_flannel_from_self_in" {
  type              = "ingress"
  from_port         = 8472
  to_port           = 8472
  protocol          = "udp"
  self              = true
  security_group_id = aws_security_group.worker.id
  description       = "Flannel VXLAN from other workers"
}

# --- Infra Rules (aws_security_group.infra) ---
resource "aws_security_group_rule" "infra_ssh_from_public_in" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.public.id
  security_group_id        = aws_security_group.infra.id
  description              = "SSH access from control plane"
}

resource "aws_security_group_rule" "infra_mongo_from_public_in" {
  description              = "Allow MongoDB access from infra public security group"
  type                     = "ingress"
  from_port                = 27017
  to_port                  = 27017
  protocol                 = "tcp"
  security_group_id        = aws_security_group.infra.id
  source_security_group_id = aws_security_group.public.id
}

resource "aws_security_group_rule" "infra_redis_from_public_in" {
  description              = "Allow Redis access from infra public security group"
  type                     = "ingress"
  from_port                = 6379
  to_port                  = 6379
  protocol                 = "tcp"
  security_group_id        = aws_security_group.infra.id
  source_security_group_id = aws_security_group.public.id
}

resource "aws_security_group_rule" "infra_kafka_ui_from_public_in" {
  description              = "Allow Kafka UI access from infra public security group"
  type                     = "ingress"
  from_port                = 9000
  to_port                  = 9000
  protocol                 = "tcp"
  security_group_id        = aws_security_group.infra.id
  source_security_group_id = aws_security_group.public.id
}

# --- Database Rules (aws_security_group.database) ---
resource "aws_security_group_rule" "db_psql_from_public_in" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.public.id
  security_group_id        = aws_security_group.database.id
  description              = "PostgreSQL access from application"
}

resource "aws_security_group_rule" "db_psql_from_any_in" {
  type              = "ingress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.database.id
  description       = "PostgreSQL direct access for development"
}


# --- EXISTING STANDALONE RULES (Unchanged) ---

resource "aws_security_group_rule" "infra_from_workers" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.infra.id
  source_security_group_id = aws_security_group.worker.id
  description              = "Allow worker nodes to reach infra host"
}

resource "aws_security_group_rule" "workers_from_control_plane" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.worker.id
  source_security_group_id = aws_security_group.public.id
  description              = "Allow control plane to reach worker nodes"
}

resource "aws_security_group_rule" "workers_from_alb" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.worker.id
  source_security_group_id = aws_security_group.alb.id
  description              = "Allow ALB to forward web traffic to workers"
}

resource "aws_security_group_rule" "control_plane_from_workers" {
  type                     = "ingress"
  from_port                = 6443
  to_port                  = 6443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.public.id
  source_security_group_id = aws_security_group.worker.id
  description              = "Allow worker nodes to reach the control plane API"
}

resource "aws_security_group_rule" "dashboard_from_control_plane" {
  type                     = "ingress"
  from_port                = 8443
  to_port                  = 8443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.worker.id
  source_security_group_id = aws_security_group.public.id
  description              = "Allow control plane to reach Kubernetes dashboard"
}