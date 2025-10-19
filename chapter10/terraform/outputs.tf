output "alb_dns_name" {
  description = "Public DNS name of the Chapter 10 ALB"
  value       = aws_lb.app.dns_name
}

output "alb_security_group_id" {
  description = "Security group protecting the Chapter 10 ALB"
  value       = aws_security_group.alb.id
}

output "alb_target_group_arn" {
  description = "ARN of the ALB target group for the nginx NodePort"
  value       = aws_lb_target_group.app.arn
}

output "alb_listener_arn" {
  description = "ARN of the HTTP listener"
  value       = aws_lb_listener.http.arn
}
