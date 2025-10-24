resource "aws_lb" "cluster" {
  name               = "tktly-alb-${terraform.workspace}"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id
  idle_timeout       = 600

  tags = {
    Name        = "ticketly-cluster-alb"
    Environment = terraform.workspace
  }
}

resource "aws_lb_target_group" "worker" {
  name     = "tktly-tg-${terraform.workspace}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.ticketly_vpc.id

  health_check {
    enabled             = true
    interval            = 30
    path                = "/"
    port                = "traffic-port"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    matcher             = "200-499"
  }

  tags = {
    Name        = "ticketly-worker-tg"
    Environment = terraform.workspace
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.cluster.arn
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

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.cluster.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.api_domain_ssl_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.worker.arn
  }
}

resource "aws_lb_target_group_attachment" "worker" {
  for_each = aws_instance.worker

  target_group_arn = aws_lb_target_group.worker.arn
  target_id        = each.value.id
  port             = 80
}

# -----------------------------------------------------------------------------
# Web Application Firewall (WAF) - protects the ALB against common exploits
# -----------------------------------------------------------------------------

resource "aws_wafv2_web_acl" "alb" {
  name  = "ticketly-alb-waf-${terraform.workspace}"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "ticketlyAlbWaf"
    sampled_requests_enabled   = true
  }

  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "commonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "knownBadInputsRuleSet"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWS-AWSManagedRulesSQLiRuleSet"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "sqliRuleSet"
      sampled_requests_enabled   = true
    }
  }

  tags = {
    Name        = "ticketly-alb-waf"
    Environment = terraform.workspace
  }
}

resource "aws_wafv2_web_acl_association" "alb" {
  resource_arn = aws_lb.cluster.arn
  web_acl_arn  = aws_wafv2_web_acl.alb.arn
}
