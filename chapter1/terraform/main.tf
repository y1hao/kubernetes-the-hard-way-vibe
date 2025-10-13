module "network" {
  source = "./modules/network"

  name_prefix = "kthw"
  vpc_cidr    = var.vpc_cidr
  tags        = local.base_tags
}
