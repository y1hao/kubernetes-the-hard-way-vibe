locals {
  base_tags = merge({
    Project = "K8sHardWay"
    Env     = "Lab"
    Chapter = "2"
  }, var.extra_tags)

  control_plane_nodes = {
    "cp-a" = {
      az_suffix  = "a"
      private_ip = "10.240.16.10"
      role       = "control-plane"
    }
    "cp-b" = {
      az_suffix  = "b"
      private_ip = "10.240.48.10"
      role       = "control-plane"
    }
    "cp-c" = {
      az_suffix  = "c"
      private_ip = "10.240.80.10"
      role       = "control-plane"
    }
  }

  worker_nodes = {
    "worker-a" = {
      az_suffix  = "a"
      private_ip = "10.240.16.20"
      role       = "worker"
    }
    "worker-b" = {
      az_suffix  = "b"
      private_ip = "10.240.48.20"
      role       = "worker"
    }
    "worker-c" = {
      az_suffix  = "c"
      private_ip = "10.240.80.20"
      role       = "worker"
    }
  }

  node_definitions = merge(local.control_plane_nodes, local.worker_nodes)

  private_subnet_ids = try(data.terraform_remote_state.chapter1.outputs.private_subnet_ids, {})

  control_plane_security_group_id = try(data.terraform_remote_state.chapter1.outputs.control_plane_security_group_id, null)

  worker_security_group_id = try(data.terraform_remote_state.chapter1.outputs.worker_security_group_id, null)

  bastion_security_group_id = try(data.terraform_remote_state.chapter1.outputs.bastion_security_group_id, null)

  cloud_init_template_paths = {
    "control-plane" = abspath("${path.module}/../cloud-init/control-plane.yaml")
    "worker"        = abspath("${path.module}/../cloud-init/worker.yaml")
  }
}
