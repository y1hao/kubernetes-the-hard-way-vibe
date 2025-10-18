locals {
  vpc_id              = try(local.network_outputs.vpc_id, null)
  private_subnet_list = values(local.private_subnet_ids)
}

resource "aws_lb" "api" {
  name               = "kthw-api-nlb"
  load_balancer_type = "network"
  internal           = true
  subnets            = local.private_subnet_list

  enable_cross_zone_load_balancing = true

  tags = merge(local.base_tags, {
    Name = "kthw-api-nlb"
    Role = "ControlPlaneLB"
  })
}

resource "aws_lb_target_group" "api" {
  name     = "kthw-api-targets"
  port     = 6443
  protocol = "TCP"
  vpc_id   = local.vpc_id

  health_check {
    protocol = "TCP"
    port     = "6443"
  }

  tags = merge(local.base_tags, {
    Name = "kthw-api-targets"
    Role = "ControlPlaneLB"
  })
}

resource "aws_lb_target_group_attachment" "control_planes" {
  for_each = local.control_plane_instance_ids

  target_group_arn = aws_lb_target_group.api.arn
  target_id        = each.value
  port             = 6443
}

resource "aws_lb_listener" "api" {
  load_balancer_arn = aws_lb.api.arn
  port              = 6443
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }
}

resource "aws_route53_zone" "kthw_lab" {
  name = "kthw.lab"
  vpc {
    vpc_id = local.vpc_id
  }

  comment = "Private zone for kthw.lab"

  tags = merge(local.base_tags, {
    Name = "kthw.lab"
    Role = "PrivateDNS"
  })
}

resource "aws_route53_record" "api" {
  zone_id = aws_route53_zone.kthw_lab.zone_id
  name    = "api.kthw.lab"
  type    = "A"

  alias {
    name                   = aws_lb.api.dns_name
    zone_id                = aws_lb.api.zone_id
    evaluate_target_health = true
  }
}
