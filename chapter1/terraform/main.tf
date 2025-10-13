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

  name_prefix           = "kthw"
  vpc_id                = module.network.vpc_id
  tags                  = local.base_tags
  admin_cidr_blocks     = var.admin_cidr_blocks
  pod_cidr              = var.pod_cidr
  service_cidr          = var.service_cidr
  nodeport_source_cidrs = var.nodeport_source_cidrs
}
