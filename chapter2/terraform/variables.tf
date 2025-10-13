variable "aws_region" {
  description = "AWS region to deploy the Chapter 2 compute stack into"
  type        = string
  default     = "ap-southeast-2"
}

variable "instance_type" {
  description = "EC2 instance type for both control plane and worker nodes"
  type        = string
  default     = "t3.medium"
}

variable "root_volume_size_gb" {
  description = "Size of the root volume (GiB) attached to each node"
  type        = number
  default     = 20
}

variable "ssh_key_name" {
  description = "Name of the AWS key pair to attach for SSH access"
  type        = string
  default     = "kthw-lab"
}

variable "ami_ssm_parameter_name" {
  description = "SSM parameter name that exposes the latest Ubuntu 22.04 LTS AMI"
  type        = string
  default     = "/aws/service/canonical/ubuntu/server/22.04/stable/current/amd64/hvm/ebs-gp3"
}

variable "extra_tags" {
  description = "Additional tags to apply to all Chapter 2 resources"
  type        = map(string)
  default     = {}
}
