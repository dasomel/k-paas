# LoadBalancer Module Variables

variable "master_lb_name" {
  description = "Master load balancer name"
  type        = string
  default     = "master-lb"
}

variable "worker_lb_name" {
  description = "Worker load balancer name"
  type        = string
  default     = "worker-lb"
}

variable "availability_zone" {
  description = "Availability zone"
  type        = string
  default     = "kr-central-2-a"
}

variable "subnet_id" {
  description = "Subnet ID to attach load balancers"
  type        = string
}

variable "master_private_ips" {
  description = "List of master node private IPs"
  type        = list(string)
}

variable "worker_private_ips" {
  description = "List of worker node private IPs"
  type        = list(string)
}

# Dependencies
variable "master_instances_dependency" {
  description = "Master instances dependency"
  type        = any
  default     = null
}

variable "master_public_ips_dependency" {
  description = "Master public IPs dependency"
  type        = any
  default     = null
}

variable "worker_instances_dependency" {
  description = "Worker instances dependency"
  type        = any
  default     = null
}

variable "worker_public_ips_dependency" {
  description = "Worker public IPs dependency"
  type        = any
  default     = null
}
