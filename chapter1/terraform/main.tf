module "network" {
  source = "./modules/network"

  name_prefix               = "kthw"
  vpc_cidr                  = var.vpc_cidr
  availability_zone_ids     = var.availability_zone_ids
  availability_zone_names   = var.availability_zone_names
  public_subnet_cidrs       = var.public_subnet_cidrs
  private_subnet_cidrs      = var.private_subnet_cidrs
  enable_nat_gateway        = var.enable_nat_gateway
  nat_gateway_subnet_suffix = var.nat_gateway_subnet_suffix
  tags                      = local.base_tags
}

module "security" {
  source = "./modules/security"

  name_prefix              = "kthw"
  vpc_id                   = module.network.vpc_id
  tags                     = local.base_tags
  admin_cidr_blocks        = var.admin_cidr_blocks
  pod_cidr                 = var.pod_cidr
  service_cidr             = var.service_cidr
  nodeport_source_cidrs    = var.nodeport_source_cidrs
  internal_api_cidr_blocks = values(var.private_subnet_cidrs)
}

data "aws_ami" "bastion" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.bastion.id
  instance_type               = var.bastion_instance_type
  subnet_id                   = module.network.public_subnet_ids[var.bastion_subnet_suffix]
  private_ip                  = var.bastion_private_ip
  associate_public_ip_address = true
  key_name                    = var.key_pair_name

  vpc_security_group_ids = [module.security.bastion_security_group_id]

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_size           = var.bastion_root_volume_size_gb
    volume_type           = "gp3"
    delete_on_termination = true
    tags                  = merge(local.base_tags, { Name = "kthw-bastion-root" })
  }

  tags = merge(
    local.base_tags,
    {
      Name = "kthw-bastion"
      Role = "Bastion"
    }
  )
}
