locals {
  base_tags = merge({
    Project = "K8sHardWay"
    Env     = "Lab"
    Chapter = "10"
  }, var.extra_tags)

  network_outputs = data.terraform_remote_state.chapter1.outputs
  compute_outputs = data.terraform_remote_state.chapter2.outputs

  public_subnet_ids = try(local.network_outputs.public_subnet_ids, {})
  worker_security_group_id = try(local.network_outputs.worker_security_group_id, null)

  node_metadata = try(local.compute_outputs.node_metadata, {})

  worker_instances = {
    for name, meta in local.node_metadata :
    name => meta if try(meta.role, "") == "worker"
  }
}
