variable "name_prefix" {
  description = "Prefix applied to security group names"
  type        = string
}

variable "vpc_id" {
  description = "VPC identifier that hosts the security groups"
  type        = string
}

variable "tags" {
  description = "Common tags applied to security groups"
  type        = map(string)
  default     = {}
}

variable "admin_cidr_blocks" {
  description = "CIDR blocks allowed to access administrative endpoints (e.g., bastion, SSH)"
  type        = list(string)
  default     = []
}

variable "pod_cidr" {
  description = "Pod CIDR used by the cluster"
  type        = string
}

variable "service_cidr" {
  description = "Service CIDR used by the cluster"
  type        = string
}

variable "nodeport_source_cidrs" {
  description = "Optional CIDR blocks permitted to reach worker NodePort services"
  type        = list(string)
  default     = []
}

variable "internal_api_cidr_blocks" {
  description = "CIDR blocks inside the VPC allowed to reach the kube-apiserver via the load balancer"
  type        = list(string)
  default     = []
}
