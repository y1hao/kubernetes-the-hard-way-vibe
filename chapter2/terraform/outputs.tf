output "node_metadata" {
  description = "Map of node name to role, instance id, private IP, AZ suffix, and subnet"
  value = {
    for name, cfg in local.node_definitions :
    name => {
      role        = cfg.role
      az_suffix   = cfg.az_suffix
      private_ip  = aws_instance.nodes[name].private_ip
      instance_id = aws_instance.nodes[name].id
      subnet_id   = aws_instance.nodes[name].subnet_id
    }
  }
}

output "control_plane_private_ips" {
  description = "Map of control plane node name to private IP"
  value = {
    for name, cfg in local.control_plane_nodes :
    name => aws_instance.nodes[name].private_ip
  }
}

output "worker_private_ips" {
  description = "Map of worker node name to private IP"
  value = {
    for name, cfg in local.worker_nodes :
    name => aws_instance.nodes[name].private_ip
  }
}

output "cloud_init_template_paths" {
  description = "Absolute paths to the cloud-init templates used for each node role"
  value       = local.cloud_init_template_paths
}

output "default_ssh_user" {
  description = "Default SSH user for Ubuntu images"
  value       = "ubuntu"
}
