# Application Load Balancer routing public traffic into the private worker nodes.
resource "aws_lb" "cluster" {
  count = local.is_prod ? 1 : 0

  name               = "tktly-alb-${terraform.workspace}"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.alb[0].id]
  subnets            = aws_subnet.public[*].id

  tags = {
    Name        = "ticketly-cluster-alb"
    Environment = terraform.workspace
  }
}

# Target group representing the worker nodes that serve cluster ingress.
resource "aws_lb_target_group" "worker" {
  count = local.is_prod ? 1 : 0

  name     = "tktly-tg-${terraform.workspace}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.ticketly_vpc[0].id

  health_check {
    enabled             = true
    interval            = 30
    path                = "/"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200-399"
  }

  tags = {
    Name        = "ticketly-worker-tg"
    Environment = terraform.workspace
  }
}

# Listener that forwards HTTP traffic from the ALB to the worker nodes.
resource "aws_lb_listener" "http" {
  count = local.is_prod ? 1 : 0

  load_balancer_arn = aws_lb.cluster[0].arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.worker[0].arn
  }
}

# Attach each worker instance to the target group.
resource "aws_lb_target_group_attachment" "worker" {
  for_each = local.is_prod ? aws_instance.worker : {}

  target_group_arn = aws_lb_target_group.worker[0].arn
  target_id        = each.value.id
  port             = 80
}
