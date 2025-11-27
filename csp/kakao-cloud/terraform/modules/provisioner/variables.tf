# Provisioner Module Variables

variable "master_count" {
  description = "Number of master nodes"
  type        = number
}

variable "worker_count" {
  description = "Number of worker nodes"
  type        = number
}

variable "master_private_ips" {
  description = "List of master node private IPs"
  type        = list(string)
}

variable "master_public_ips" {
  description = "List of master node public IPs"
  type        = list(string)
}

variable "worker_private_ips" {
  description = "List of worker node private IPs"
  type        = list(string)
}

variable "master_lb_vip" {
  description = "Master load balancer VIP"
  type        = string
}

variable "master_lb_public_ip" {
  description = "Master load balancer public IP"
  type        = string
}

variable "worker_lb_vip" {
  description = "Worker load balancer VIP"
  type        = string
}

variable "worker_lb_public_ip" {
  description = "Worker load balancer public IP"
  type        = string
}

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

variable "terraform_dir" {
  description = "Terraform project directory"
  type        = string
}

variable "generated_dir" {
  description = "Generated scripts directory"
  type        = string
}

variable "ssh_key_path" {
  description = "Path to SSH private key"
  type        = string
}

variable "auto_install_kpaas" {
  description = "Automatically install K-PaaS after provisioning"
  type        = bool
  default     = true
}

variable "master_lb_dependency" {
  description = "Master LB dependency"
  type        = any
  default     = null
}
