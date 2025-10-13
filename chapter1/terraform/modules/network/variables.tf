variable "name_prefix" {
  description = "Prefix used for naming network resources"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "tags" {
  description = "Common tags applied to network resources"
  type        = map(string)
  default     = {}
}
