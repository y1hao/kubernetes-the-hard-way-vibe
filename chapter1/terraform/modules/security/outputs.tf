output "bastion_security_group_id" {
  description = "Security group ID for the bastion host"
  value       = aws_security_group.bastion.id
}

output "control_plane_security_group_id" {
  description = "Security group ID for control plane nodes"
  value       = aws_security_group.control_plane.id
}

output "worker_security_group_id" {
  description = "Security group ID for worker nodes"
  value       = aws_security_group.worker.id
}

output "api_nlb_security_group_id" {
  description = "Security group ID intended for the API Network Load Balancer"
  value       = aws_security_group.api_nlb.id
}
