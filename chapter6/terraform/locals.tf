locals {
  base_tags = merge({
    Project = "K8sHardWay"
    Env     = "Lab"
    Chapter = "6"
  }, var.extra_tags)

  network_outputs = data.terraform_remote_state.chapter1.outputs
  compute_outputs = data.terraform_remote_state.chapter2.outputs

  private_subnet_ids = try(local.network_outputs.private_subnet_ids, {})

  node_metadata = try(local.compute_outputs.node_metadata, {})

  control_plane_instance_ids = {
    for name, meta in local.node_metadata :
    name => meta.instance_id if try(meta.role, "") == "control-plane"
  }
}
