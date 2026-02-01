# Master 노드 이름 접두사
variable "master_name" {}

# Worker 노드 이름 접두사
variable "worker_name" {}

# Master 노드 수 (기본값: 3)
variable "master_count" {
  description = "Number of master nodes (1 or 3 recommended for HA)"
  type        = number
  default     = 3

  validation {
    condition     = var.master_count >= 1 && var.master_count <= 5
    error_message = "master_count must be between 1 and 5 (3 recommended for HA)"
  }
}

# Worker 노드 수 (기본값: 3)
variable "worker_count" {
  description = "Number of worker nodes (minimum 1)"
  type        = number
  default     = 3

  validation {
    condition     = var.worker_count >= 1 && var.worker_count <= 10
    error_message = "worker_count must be between 1 and 10"
  }
}

# 사용할 키페어 이름
variable "key_name" {}

# 보안 그룹 이름
variable "security_group_name" {}

# Kakao Cloud Application Credential ID
variable "application_credential_id" {}

# Kakao Cloud Application Credential Secret
variable "application_credential_secret" {}

# 프로비저닝을 위한 SSH 키 경로
variable "ssh_key_path" {
  description = "Path to SSH private key for instance access"
  type        = string
  default     = "~/.ssh/id_rsa"
}

# K-PaaS 자동 설치 여부
variable "auto_install_kpaas" {
  description = "Automatically install K-PaaS after provisioning (true/false)"
  type        = bool
  default     = true
}

# Network Configuration
variable "vpc_name" {
  description = "VPC name"
  type        = string
  default     = "test-kpaas"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "172.16.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid CIDR block (e.g., 172.16.0.0/16)"
  }
}

variable "vpc_default_subnet_cidr" {
  description = "VPC default subnet CIDR"
  type        = string
  default     = "172.16.255.0/24"

  validation {
    condition     = can(cidrhost(var.vpc_default_subnet_cidr, 0))
    error_message = "vpc_default_subnet_cidr must be a valid CIDR block (e.g., 172.16.255.0/24)"
  }
}

variable "subnet_name" {
  description = "Subnet name"
  type        = string
  default     = "main_subnet"
}

variable "subnet_cidr" {
  description = "Subnet CIDR block"
  type        = string
  default     = "172.16.0.0/24"

  validation {
    condition     = can(cidrhost(var.subnet_cidr, 0))
    error_message = "subnet_cidr must be a valid CIDR block (e.g., 172.16.0.0/24)"
  }
}

variable "availability_zone" {
  description = "Availability zone"
  type        = string
  default     = "kr-central-2-a"
}

# Compute Configuration
variable "image_name" {
  description = "OS image name"
  type        = string
  default     = "Ubuntu 24.04"
}

variable "master_flavor" {
  description = "Master instance flavor (size)"
  type        = string
  default     = "t1i.large"
}

variable "worker_flavor" {
  description = "Worker instance flavor (size)"
  type        = string
  default     = "t1i.xlarge"
}

variable "volume_size" {
  description = "Boot volume size in GB (minimum 100GB recommended)"
  type        = number
  default     = 200

  validation {
    condition     = var.volume_size >= 50 && var.volume_size <= 1000
    error_message = "volume_size must be between 50 and 1000 GB"
  }
}

# Load Balancer Configuration
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

# K-PaaS Network Configuration
variable "metallb_ip_range" {
  description = "MetalLB IP range (format: start_ip-end_ip)"
  type        = string
  default     = "172.16.0.210-172.16.0.250"

  validation {
    condition     = can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}-([0-9]{1,3}\\.){3}[0-9]{1,3}$", var.metallb_ip_range))
    error_message = "metallb_ip_range must be in format: x.x.x.x-y.y.y.y (e.g., 172.16.0.210-172.16.0.250)"
  }
}

variable "ingress_nginx_ip" {
  description = "Ingress Nginx LoadBalancer IP"
  type        = string
  default     = "172.16.0.201"

  validation {
    condition     = can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}$", var.ingress_nginx_ip))
    error_message = "ingress_nginx_ip must be a valid IPv4 address (e.g., 172.16.0.201)"
  }
}

variable "portal_domain" {
  description = "Portal domain name"
  type        = string
  default     = "k-paas.io"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]*[a-z0-9]$", var.portal_domain))
    error_message = "portal_domain must be a valid domain name (e.g., k-paas.io)"
  }
}
