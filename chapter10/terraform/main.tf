locals {
  alb_name          = "kthw-ch10-alb"
  target_group_name = "kthw-ch10-app"
}

resource "aws_security_group" "alb" {
  name        = local.alb_name
  description = "Chapter 10 ALB ingress"
  vpc_id      = local.network_outputs.vpc_id

  tags = merge(local.base_tags, {
    Name = local.alb_name
  })
}

resource "aws_security_group_rule" "alb_http_ingress" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
  description       = "Allow public HTTP"
}

resource "aws_security_group_rule" "alb_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
  description       = "Allow all outbound"
}

resource "aws_security_group_rule" "worker_nodeport_from_alb" {
  count = local.worker_security_group_id == null ? 0 : 1

  type                     = "ingress"
  from_port                = 30080
  to_port                  = 30080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = local.worker_security_group_id
  description              = "Allow ALB to reach nginx NodePort"
}

resource "aws_lb" "app" {
  name               = local.alb_name
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.alb.id]
  subnets            = local.public_subnet_ids_list

  tags = merge(local.base_tags, {
    Name = local.alb_name
  })
}

resource "aws_lb_target_group" "app" {
  name        = local.target_group_name
  port        = 30080
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = local.network_outputs.vpc_id

  health_check {
    enabled             = true
    protocol            = "HTTP"
    path                = "/"
    matcher             = "200-399"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 15
    timeout             = 5
  }

  tags = merge(local.base_tags, {
    Name = local.target_group_name
  })
}

resource "aws_lb_target_group_attachment" "workers" {
  for_each = local.worker_instances

  target_group_arn = aws_lb_target_group.app.arn
  target_id        = each.value.instance_id
  port             = 30080
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}
