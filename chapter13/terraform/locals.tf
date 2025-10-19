locals {
  base_tags = merge({
    Project = "K8sHardWay"
    Env     = "Lab"
    Chapter = "13"
  }, var.extra_tags)

  network_outputs = data.terraform_remote_state.chapter1.outputs
  compute_outputs = data.terraform_remote_state.chapter2.outputs

  vpc_id = try(local.network_outputs.vpc_id, null)

  public_subnet_ids  = try(local.network_outputs.public_subnet_ids, {})
  public_subnet_list = sort(values(local.public_subnet_ids))

  control_plane_nodes = {
    for name, meta in try(local.compute_outputs.node_metadata, {}) :
    name => meta if try(meta.role, "") == "control-plane"
  }

  admin_cidrs = [for cidr in var.admin_cidr_blocks : cidr if length(trimspace(cidr)) > 0]
}
