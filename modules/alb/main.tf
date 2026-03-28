# ── Target Group ──────────────────────────────────────────────────────────────

resource "aws_lb_target_group" "app_servers" {
  name_prefix = "app-"
  port        = var.instance_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    path                = "/"
    matcher             = "200"
  }

  tags = {
    Name    = "${var.project_name}-app-tg"
    Project = var.project_name
  }
}

# ── Target Group Attachment for EC2 Instances ─────────────────────────────────

resource "aws_lb_target_group_attachment" "app_servers" {
  count = length(var.app_server_ids)

  target_group_arn = aws_lb_target_group.app_servers.arn
  target_id        = var.app_server_ids[count.index]
  port             = var.instance_port
}

# ── Application Load Balancer ─────────────────────────────────────────────────

resource "aws_lb" "main" {
  name_prefix            = "alb-"
  internal               = false
  load_balancer_type     = "application"
  security_groups        = [var.alb_security_group_id]
  subnets                = var.public_subnet_ids
  enable_deletion_protection = var.enable_deletion_protection
  enable_http2           = var.enable_http2
  enable_cross_zone_load_balancing = var.enable_cross_zone_load_balancing

  tags = {
    Name    = "${var.project_name}-alb"
    Project = var.project_name
  }
}

# ── ALB Listener ───────────────────────────────────────────────────────────────

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = var.alb_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_servers.arn
  }
}
