output "api_nlb_arn" {
  description = "ARN of the Kubernetes API Network Load Balancer"
  value       = aws_lb.api.arn
}

output "api_nlb_dns_name" {
  description = "DNS name of the internal Kubernetes API NLB"
  value       = aws_lb.api.dns_name
}

output "api_target_group_arn" {
  description = "ARN of the API server target group"
  value       = aws_lb_target_group.api.arn
}
