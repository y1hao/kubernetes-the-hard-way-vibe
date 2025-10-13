variable "aws_region" {
  description = "AWS region to deploy the Chapter 1 network substrate"
  type        = string
  default     = "ap-southeast-2"
}

variable "availability_zone_ids" {
  description = "Mapping of node suffixes to AWS availability zone IDs"
  type        = map(string)
  default = {
    a = "apse2-az1"
    b = "apse2-az2"
    c = "apse2-az3"
  }
}

variable "availability_zone_names" {
  description = "Mapping of node suffixes to AWS availability zone names"
  type        = map(string)
  default = {
    a = "ap-southeast-2a"
    b = "ap-southeast-2c"
    c = "ap-southeast-2b"
  }
}

variable "vpc_cidr" {
  description = "CIDR block for the Kubernetes lab VPC"
  type        = string
  default     = "10.240.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets keyed by AZ suffix"
  type        = map(string)
  default = {
    a = "10.240.0.0/24"
    b = "10.240.32.0/24"
    c = "10.240.64.0/24"
  }
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets keyed by AZ suffix"
  type        = map(string)
  default = {
    a = "10.240.16.0/24"
    b = "10.240.48.0/24"
    c = "10.240.80.0/24"
  }
}

variable "pod_cidr" {
  description = "Cluster-wide pod CIDR reserved for Calico"
  type        = string
  default     = "10.200.0.0/16"
}

variable "service_cidr" {
  description = "Cluster service CIDR for virtual IPs"
  type        = string
  default     = "10.32.0.0/24"
}

variable "default_tags" {
  description = "Baseline tags applied to Chapter 1 AWS resources"
  type        = map(string)
  default = {
    Project = "K8sHardWay"
    Env     = "Lab"
  }
}

variable "key_pair_name" {
  description = "Name of the AWS key pair for bastion and node access"
  type        = string
  default     = "kthw-lab"
}

variable "enable_nat_gateway" {
  description = "Controls whether a managed NAT gateway is provisioned for private subnets"
  type        = bool
  default     = true
}

variable "nat_gateway_subnet_suffix" {
  description = "AZ suffix of the public subnet hosting the managed NAT gateway"
  type        = string
  default     = "a"
}

variable "admin_cidr_blocks" {
  description = "CIDR blocks permitted to reach administrative surfaces (bastion, API access)"
  type        = list(string)
  default     = []
}

variable "nodeport_source_cidrs" {
  description = "CIDR blocks allowed to reach worker NodePort services"
  type        = list(string)
  default     = []
}
