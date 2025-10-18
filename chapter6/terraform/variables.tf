variable "aws_region" {
  description = "AWS region hosting the Kubernetes lab"
  type        = string
  default     = "ap-southeast-2"
}

variable "extra_tags" {
  description = "Optional tags to merge with chapter defaults"
  type        = map(string)
  default     = {}
}
