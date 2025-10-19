variable "aws_region" {
  description = "AWS region hosting the Kubernetes lab"
  type        = string
  default     = "ap-southeast-2"
}

variable "admin_cidr_blocks" {
  description = "List of administrator CIDR ranges allowed to reach the public kube-apiserver"
  type        = list(string)
  default     = []
}

variable "enable_cross_zone" {
  description = "Enable cross-zone load balancing on the public API NLB"
  type        = bool
  default     = true
}

variable "extra_tags" {
  description = "Optional tags to merge with chapter defaults"
  type        = map(string)
  default     = {}
}
