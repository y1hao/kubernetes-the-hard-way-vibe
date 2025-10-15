data "aws_ssm_parameters_by_path" "ubuntu_2204" {
  path            = var.ami_ssm_parameter_path
  recursive       = true
  with_decryption = false
}

resource "aws_instance" "nodes" {
  for_each = local.node_definitions

  ami                         = local.ubuntu_ami_id
  instance_type               = each.value.role == "control-plane" ? var.control_plane_instance_type : var.worker_instance_type
  subnet_id                   = local.private_subnet_ids[each.value.az_suffix]
  private_ip                  = each.value.private_ip
  key_name                    = var.ssh_key_name
  associate_public_ip_address = false

  vpc_security_group_ids = each.value.role == "control-plane" ? [local.control_plane_security_group_id] : [local.worker_security_group_id]

  user_data = templatefile(local.cloud_init_template_paths[each.value.role], {
    hostname = each.key
    role     = each.value.role
  })

  user_data_replace_on_change = true

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_size           = var.root_volume_size_gb
    volume_type           = "gp3"
    delete_on_termination = true
    tags                  = merge(local.base_tags, { "Name" = format("kthw-%s-root", each.key) })
  }

  tags = merge(
    local.base_tags,
    {
      Name        = format("kthw-%s", each.key)
      Role        = each.value.role
      Node        = each.key
      AnsibleHost = each.value.private_ip
    }
  )
}
