locals {
  tags = merge(
    var.tags,
    {
      Role = "Network"
    }
  )
}

resource "aws_security_group" "bastion" {
  name        = "${var.name_prefix}-bastion"
  description = "Bastion host ingress controls"
  vpc_id      = var.vpc_id

  tags = merge(local.tags, { Name = "${var.name_prefix}-bastion" })
}

resource "aws_security_group_rule" "bastion_ssh" {
  for_each = toset(var.admin_cidr_blocks)

  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [each.value]
  security_group_id = aws_security_group.bastion.id
  description       = "Admin SSH access"
}

resource "aws_security_group" "control_plane" {
  name        = "${var.name_prefix}-control-plane"
  description = "Kubernetes control plane ingress"
  vpc_id      = var.vpc_id

  tags = merge(local.tags, { Name = "${var.name_prefix}-control-plane" })
}

resource "aws_security_group" "worker" {
  name        = "${var.name_prefix}-worker"
  description = "Kubernetes worker ingress"
  vpc_id      = var.vpc_id

  tags = merge(local.tags, { Name = "${var.name_prefix}-worker" })
}

resource "aws_security_group" "api_nlb" {
  name        = "${var.name_prefix}-api-nlb"
  description = "Ingress to API Network Load Balancer"
  vpc_id      = var.vpc_id

  tags = merge(local.tags, { Name = "${var.name_prefix}-api-nlb" })
}

resource "aws_security_group_rule" "bastion_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.bastion.id
  description       = "Allow bastion outbound"
}

resource "aws_security_group_rule" "control_plane_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.control_plane.id
  description       = "Allow control plane outbound"
}

resource "aws_security_group_rule" "worker_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.worker.id
  description       = "Allow worker outbound"
}

resource "aws_security_group_rule" "api_nlb_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.api_nlb.id
  description       = "Allow API NLB outbound"
}

resource "aws_security_group_rule" "control_plane_ssh" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion.id
  security_group_id        = aws_security_group.control_plane.id
  description              = "SSH from bastion"
}

resource "aws_security_group_rule" "worker_ssh" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion.id
  security_group_id        = aws_security_group.worker.id
  description              = "SSH from bastion"
}

resource "aws_security_group_rule" "control_plane_api_from_workers" {
  type                     = "ingress"
  from_port                = 6443
  to_port                  = 6443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.worker.id
  security_group_id        = aws_security_group.control_plane.id
  description              = "Kube-apiserver from workers"
}

resource "aws_security_group_rule" "control_plane_api_from_bastion" {
  type                     = "ingress"
  from_port                = 6443
  to_port                  = 6443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion.id
  security_group_id        = aws_security_group.control_plane.id
  description              = "Kubectl via bastion"
}

resource "aws_security_group_rule" "control_plane_etcd_peer" {
  type                     = "ingress"
  from_port                = 2380
  to_port                  = 2380
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.control_plane.id
  security_group_id        = aws_security_group.control_plane.id
  description              = "etcd peer traffic"
}

resource "aws_security_group_rule" "control_plane_etcd_client" {
  type                     = "ingress"
  from_port                = 2379
  to_port                  = 2379
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.control_plane.id
  security_group_id        = aws_security_group.control_plane.id
  description              = "etcd client traffic"
}

resource "aws_security_group_rule" "worker_kubelet" {
  type                     = "ingress"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.control_plane.id
  security_group_id        = aws_security_group.worker.id
  description              = "Kubelet API from control plane"
}

resource "aws_security_group_rule" "worker_nodeport" {
  count = length(var.nodeport_source_cidrs) > 0 ? 1 : 0

  type              = "ingress"
  from_port         = 30000
  to_port           = 32767
  protocol          = "tcp"
  cidr_blocks       = var.nodeport_source_cidrs
  security_group_id = aws_security_group.worker.id
  description       = "NodePort exposure"
}

resource "aws_security_group_rule" "api_nlb_ingress" {
  count = length(var.admin_cidr_blocks) > 0 ? 1 : 0

  type              = "ingress"
  from_port         = 6443
  to_port           = 6443
  protocol          = "tcp"
  cidr_blocks       = var.admin_cidr_blocks
  security_group_id = aws_security_group.api_nlb.id
  description       = "Administrative API access"
}
