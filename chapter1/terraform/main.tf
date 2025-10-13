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
