module "network" {
  source = "./modules/network"

  name_prefix             = "kthw"
  vpc_cidr                = var.vpc_cidr
  availability_zone_ids   = var.availability_zone_ids
  availability_zone_names = var.availability_zone_names
  public_subnet_cidrs     = var.public_subnet_cidrs
  private_subnet_cidrs    = var.private_subnet_cidrs
  tags                    = local.base_tags
}
