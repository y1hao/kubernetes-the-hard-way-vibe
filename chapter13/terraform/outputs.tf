output "public_api_nlb_dns_name" {
  description = "AWS-managed DNS name for the public kube-apiserver NLB"
  value       = aws_lb.public_api.dns_name
}

output "public_api_nlb_arn" {
  description = "ARN for the public kube-apiserver NLB"
  value       = aws_lb.public_api.arn
}

output "public_api_target_group_arn" {
  description = "Target group ARN used by the public kube-apiserver NLB"
  value       = aws_lb_target_group.public_api.arn
}

output "public_api_security_group_id" {
  description = "Security group ID that gates admin access to the kube-apiserver"
  value       = aws_security_group.public_api.id
}
