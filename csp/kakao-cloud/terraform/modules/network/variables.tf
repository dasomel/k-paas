# Network Module Variables

variable "vpc_name" {
  description = "VPC name"
  type        = string
  default     = "test-kpaas"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "172.16.0.0/16"
}

variable "vpc_default_subnet_cidr" {
  description = "VPC default subnet CIDR block"
  type        = string
  default     = "172.16.255.0/24"
}

variable "subnet_name" {
  description = "Main subnet name"
  type        = string
  default     = "main_subnet"
}

variable "subnet_cidr" {
  description = "Main subnet CIDR block"
  type        = string
  default     = "172.16.0.0/24"
}

variable "availability_zone" {
  description = "Availability zone"
  type        = string
  default     = "kr-central-2-a"
}
