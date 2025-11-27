# Security Module Variables

variable "security_group_name" {
  description = "Security group name"
  type        = string
}

variable "description" {
  description = "Security group description"
  type        = string
  default     = "K-PaaS Terraform managed security group"
}

variable "vpc_cidr" {
  description = "VPC CIDR block for internal traffic rules"
  type        = string
  default     = "172.16.0.0/16"
}
