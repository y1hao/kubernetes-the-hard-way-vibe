locals {
  load_balancer_name  = "kthw-public-api-nlb"
  target_group_name   = "kthw-public-api-targets"
  security_group_name = "kthw-public-api"
}

resource "aws_security_group" "public_api" {
  name        = local.security_group_name
  description = "Public kube-apiserver admin ingress"
  vpc_id      = local.vpc_id

  tags = merge(local.base_tags, {
    Name = local.security_group_name
    Role = "PublicApiAccess"
  })
}

resource "aws_security_group_rule" "public_api_admin_ingress" {
  for_each = toset(local.admin_cidrs)

  type              = "ingress"
  from_port         = 6443
  to_port           = 6443
  protocol          = "tcp"
  cidr_blocks       = [each.value]
  security_group_id = aws_security_group.public_api.id
  description       = "Admin kubectl access"
}

resource "aws_security_group_rule" "public_api_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.public_api.id
  description       = "Allow outbound"
}

resource "aws_lb" "public_api" {
  name               = local.load_balancer_name
  load_balancer_type = "network"
  internal           = false
  subnets            = local.public_subnet_list

  enable_cross_zone_load_balancing = var.enable_cross_zone

  tags = merge(local.base_tags, {
    Name = local.load_balancer_name
    Role = "PublicApi"
  })
}

resource "aws_lb_target_group" "public_api" {
  name     = local.target_group_name
  port     = 6443
  protocol = "TCP"
  vpc_id   = local.vpc_id

  health_check {
    protocol = "TCP"
    port     = "6443"
  }

  tags = merge(local.base_tags, {
    Name = local.target_group_name
    Role = "PublicApi"
  })
}

resource "aws_lb_target_group_attachment" "control_planes" {
  for_each = local.control_plane_nodes

  target_group_arn = aws_lb_target_group.public_api.arn
  target_id        = each.value.instance_id
  port             = 6443
}

resource "aws_lb_listener" "public_api" {
  load_balancer_arn = aws_lb.public_api.arn
  port              = 6443
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.public_api.arn
  }
}

data "aws_instance" "control_planes" {
  for_each = local.control_plane_nodes

  instance_id = each.value.instance_id
}

resource "aws_network_interface_sg_attachment" "public_api" {
  for_each = data.aws_instance.control_planes

  security_group_id    = aws_security_group.public_api.id
  network_interface_id = each.value.primary_network_interface_id
}
