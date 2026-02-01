# Shared Variables for All Layers
# 이 파일을 각 레이어에서 symlink로 참조하거나 복사하여 사용

#####################################################################
# Fixed IP Configuration - 모든 레이어에서 동일하게 사용
#####################################################################
variable "master_private_ips" {
  description = "Fixed private IPs for master nodes"
  type        = list(string)
  default     = ["172.16.0.101", "172.16.0.102", "172.16.0.103"]
}

variable "worker_private_ips" {
  description = "Fixed private IPs for worker nodes"
  type        = list(string)
  default     = ["172.16.0.111", "172.16.0.112", "172.16.0.113"]
}

#####################################################################
# Network Configuration
#####################################################################
variable "vpc_name" {
  description = "VPC name"
  type        = string
  default     = "kpaas-vpc"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "172.16.0.0/16"
}

variable "subnet_name" {
  description = "Subnet name"
  type        = string
  default     = "kpaas-subnet"
}

variable "subnet_cidr" {
  description = "Subnet CIDR block"
  type        = string
  default     = "172.16.0.0/24"
}

variable "availability_zone" {
  description = "Availability zone"
  type        = string
  default     = "kr-central-2-a"
}

#####################################################################
# K-PaaS Configuration
#####################################################################
variable "metallb_ip_range" {
  description = "MetalLB IP range"
  type        = string
  default     = "172.16.0.210-172.16.0.250"
}

variable "ingress_nginx_ip" {
  description = "Ingress Nginx LoadBalancer IP"
  type        = string
  default     = "172.16.0.201"
}

variable "portal_domain" {
  description = "Portal domain name"
  type        = string
  default     = "k-paas.io"
}
