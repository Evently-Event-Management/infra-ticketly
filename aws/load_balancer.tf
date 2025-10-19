# Application Load Balancer routing public traffic into the private worker nodes.
resource "aws_lb" "cluster" {
  count = local.is_prod ? 1 : 0

  name               = "tktly-alb-${terraform.workspace}"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.alb[0].id]
  subnets            = aws_subnet.public[*].id
  idle_timeout       = 600  # 10 minutes to support Server-Sent Events (SSE)

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
    port                = "traffic-port"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    matcher             = "200-499" # Treat 404s from Traefik as healthy
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
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# HTTPS listener with SSL certificate
resource "aws_lb_listener" "https" {
  count = local.is_prod ? 1 : 0

  load_balancer_arn = aws_lb.cluster[0].arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.api_domain_ssl_arn

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
