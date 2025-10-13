variable "name_prefix" {
  description = "Prefix used for naming network resources"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "availability_zone_ids" {
  description = "Mapping of node suffixes to AWS availability zone IDs"
  type        = map(string)
}

variable "availability_zone_names" {
  description = "Mapping of node suffixes to AWS availability zone names"
  type        = map(string)
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets keyed by AZ suffix"
  type        = map(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets keyed by AZ suffix"
  type        = map(string)
}

variable "tags" {
  description = "Common tags applied to network resources"
  type        = map(string)
  default     = {}
}
