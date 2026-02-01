# Layer 2: LoadBalancer Variables

variable "application_credential_id" {
  description = "Kakao Cloud Application Credential ID"
  type        = string
}

variable "application_credential_secret" {
  description = "Kakao Cloud Application Credential Secret"
  type        = string
  sensitive   = true
}

variable "vpc_cidr" {
  description = "VPC CIDR for security group rules"
  type        = string
  default     = "172.16.0.0/16"
}

variable "security_group_name" {
  description = "Security Group name"
  type        = string
  default     = "kpaas-sg"
}

variable "master_lb_name" {
  description = "Master Load Balancer name"
  type        = string
  default     = "kpaas-master-lb"
}

variable "worker_lb_name" {
  description = "Worker Load Balancer name"
  type        = string
  default     = "kpaas-worker-lb"
}

#####################################################################
# Fixed IP Configuration - LB Target으로 사용
#####################################################################
variable "master_private_ips" {
  description = "Fixed private IPs for master nodes (LB targets)"
  type        = list(string)
  default     = ["172.16.0.101", "172.16.0.102", "172.16.0.103"]
}

variable "worker_private_ips" {
  description = "Fixed private IPs for worker nodes (LB targets)"
  type        = list(string)
  default     = ["172.16.0.111", "172.16.0.112", "172.16.0.113"]
}
