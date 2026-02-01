# Layer 1: Network Variables

variable "application_credential_id" {
  description = "Kakao Cloud Application Credential ID"
  type        = string
}

variable "application_credential_secret" {
  description = "Kakao Cloud Application Credential Secret"
  type        = string
  sensitive   = true
}

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

variable "vpc_default_subnet_cidr" {
  description = "VPC default subnet CIDR"
  type        = string
  default     = "172.16.255.0/24"
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

variable "key_name" {
  description = "SSH Key Pair name"
  type        = string
  default     = "KPAAS_KEYPAIR"
}
