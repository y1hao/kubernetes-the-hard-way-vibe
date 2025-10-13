output "vpc_id" {
  description = "Identifier of the Kubernetes lab VPC"
  value       = module.network.vpc_id
}

output "internet_gateway_id" {
  description = "Identifier of the internet gateway"
  value       = module.network.internet_gateway_id
}
