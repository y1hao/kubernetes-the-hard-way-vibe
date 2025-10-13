output "vpc_id" {
  description = "Identifier of the Kubernetes lab VPC"
  value       = aws_vpc.this.id
}

output "vpc_arn" {
  description = "ARN of the Kubernetes lab VPC"
  value       = aws_vpc.this.arn
}

output "internet_gateway_id" {
  description = "Identifier for the internet gateway"
  value       = aws_internet_gateway.this.id
}

output "public_route_table_id" {
  description = "Identifier for the main/public route table"
  value       = aws_route_table.public.id
}

output "public_subnet_ids" {
  description = "Map of AZ suffix to public subnet IDs"
  value       = { for suffix, subnet in aws_subnet.public : suffix => subnet.id }
}

output "private_subnet_ids" {
  description = "Map of AZ suffix to private subnet IDs"
  value       = { for suffix, subnet in aws_subnet.private : suffix => subnet.id }
}
