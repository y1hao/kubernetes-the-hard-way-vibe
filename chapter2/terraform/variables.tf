variable "aws_region" {
  description = "AWS region to deploy the Chapter 2 compute stack into"
  type        = string
  default     = "ap-southeast-2"
}

variable "control_plane_instance_type" {
  description = "EC2 instance type for control plane nodes"
  type        = string
  default     = "t3.medium"
}

variable "worker_instance_type" {
  description = "EC2 instance type for worker nodes"
  type        = string
  default     = "t3.small"
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

variable "ami_ssm_parameter_path" {
  description = "SSM parameter path containing Ubuntu 22.04 LTS AMI IDs"
  type        = string
  default     = "/aws/service/canonical/ubuntu/server/22.04/stable"
}

variable "ami_ssm_parameter_suffix" {
  description = "Suffix appended to the SSM parameter path to select the desired image (e.g., amd64/hvm/ebs-gp2/ami-id)"
  type        = string
  default     = "amd64/hvm/ebs-gp2/ami-id"
}

variable "extra_tags" {
  description = "Additional tags to apply to all Chapter 2 resources"
  type        = map(string)
  default     = {}
}
