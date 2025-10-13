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
