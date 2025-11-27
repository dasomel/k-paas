# Compute Module Variables

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
  description = "OS image name"
  type        = string
  default     = "Ubuntu 24.04"
}

variable "instance_flavor" {
  description = "Instance flavor (size)"
  type        = string
  default     = "t1i.xlarge"
}

variable "volume_size" {
  description = "Boot volume size in GB"
  type        = number
  default     = 200
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID to attach instances"
  type        = string
}

variable "security_group_name" {
  description = "Security group name to apply"
  type        = string
}

variable "cloud_init_base64" {
  description = "Base64 encoded cloud-init user data"
  type        = string
}
