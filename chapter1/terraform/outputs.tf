output "vpc_id" {
  description = "Identifier of the Kubernetes lab VPC"
  value       = module.network.vpc_id
}

output "internet_gateway_id" {
  description = "Identifier of the internet gateway"
  value       = module.network.internet_gateway_id
}

output "public_subnet_ids" {
  description = "Map of AZ suffix to public subnet IDs"
  value       = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Map of AZ suffix to private subnet IDs"
  value       = module.network.private_subnet_ids
}

output "nat_gateway_id" {
  description = "Identifier of the managed NAT gateway"
  value       = module.network.nat_gateway_id
}

output "nat_eip_allocation_id" {
  description = "Allocation ID for the managed NAT gateway EIP"
  value       = module.network.nat_eip_allocation_id
}

output "bastion_security_group_id" {
  description = "Security group ID for bastion access"
  value       = module.security.bastion_security_group_id
}

output "control_plane_security_group_id" {
  description = "Security group ID for control plane nodes"
  value       = module.security.control_plane_security_group_id
}

output "worker_security_group_id" {
  description = "Security group ID for worker nodes"
  value       = module.security.worker_security_group_id
}

output "api_nlb_security_group_id" {
  description = "Security group ID for the API load balancer"
  value       = module.security.api_nlb_security_group_id
}

output "bastion_instance_id" {
  description = "Identifier of the bastion EC2 instance"
  value       = aws_instance.bastion.id
}

output "bastion_private_ip" {
  description = "Private IP address of the bastion"
  value       = aws_instance.bastion.private_ip
}

output "bastion_public_ip" {
  description = "Public IP address of the bastion"
  value       = aws_instance.bastion.public_ip
}
