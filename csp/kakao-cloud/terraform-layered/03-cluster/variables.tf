# Layer 3: Cluster Variables

variable "application_credential_id" {
  description = "Kakao Cloud Application Credential ID"
  type        = string
}

variable "application_credential_secret" {
  description = "Kakao Cloud Application Credential Secret"
  type        = string
  sensitive   = true
}

#####################################################################
# Compute Configuration
#####################################################################
variable "master_name" {
  description = "Master node name prefix"
  type        = string
  default     = "master"
}

variable "worker_name" {
  description = "Worker node name prefix"
  type        = string
  default     = "worker"
}

variable "master_count" {
  description = "Number of master nodes"
  type        = number
  default     = 3
}

variable "worker_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 3
}

variable "image_name" {
  description = "OS Image name"
  type        = string
  default     = "Ubuntu 24.04"
}

variable "master_flavor" {
  description = "Master node instance type"
  type        = string
  default     = "t1i.large"
}

variable "worker_flavor" {
  description = "Worker node instance type"
  type        = string
  default     = "t1i.xlarge"
}

variable "volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 200
}

# NOTE: key_name and ssh_key_path are now from 01-network layer

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

variable "auto_install_kpaas" {
  description = "Automatically install K-PaaS after provisioning"
  type        = bool
  default     = true
}
