############################################################
# Kakao Cloud Terraform (OpenStack 호환 구조, 단일파일)
############################################################

terraform {
  required_version = ">= 1.0"
  required_providers {
    kakaocloud = {
      source  = "kakaoenterprise/kakaocloud"
      version = "~> 1.0"
    }
  }
}

provider "kakaocloud" {
  application_credential_id     = var.application_credential_id
  application_credential_secret = var.application_credential_secret
  region                       = var.region
}

############################################################
# Variables (OpenStack 이름 구조 유지)
############################################################

variable "application_credential_id" {
  description = "Kakao Cloud 인증 ID"
  type        = string
  sensitive   = true
}
variable "application_credential_secret" {
  description = "Kakao Cloud 인증 Secret"
  type        = string
  sensitive   = true
}
variable "region" {
  description = "Kakao Cloud region"
  type        = string
  default     = "kr-central-2"
}
variable "availability_zone" {
  description = "Availability Zone"
  type        = string
  default     = "kr-central-2-a"
}
variable "master_node_name" {
  description = "Master node name"
  type        = string
  default     = "opentofu-master-node"
}
variable "worker_node_name" {
  description = "Worker node name"
  type        = string
  default     = "opentofu-worker-node"
}
variable "image_name" {
  description = "OS Image Name"
  type        = string
  default     = "Ubuntu 20.04"
}
variable "instance_flavor" {
  description = "Instance flavor"
  type        = string
  default     = "t1i.xlarge"
}
variable "volume_size" {
  description = "Boot Volume Size (GB)"
  type        = number
  default     = 80
}
variable "key_pair_name" {
  description = "SSH Key Pair Name"
  type        = string
  default     = "cp-opentofu-keypair"
}
variable "vpc_name" {
  description = "VPC Name"
  type        = string
  default     = "cp-network"
}
variable "subnet_name" {
  description = "Subnet Name"
  type        = string
  default     = "cp-subnet"
}
variable "security_group_name" {
  description = "Security Group Name"
  type        = string
  default     = "cp-secgroup"
}

############################################################
# Data Sources (기존 리소스 조회)
############################################################

data "kakaocloud_images" "ubuntu" {}
data "kakaocloud_instance_flavors" "flavors" {}

data "kakaocloud_vpcs" "cp_network" {
  name_filter = var.vpc_name
}
data "kakaocloud_subnets" "cp_subnet" {
  vpc_id      = data.kakaocloud_vpcs.cp_network.vpcs[0].id
  name_filter = var.subnet_name
}
data "kakaocloud_security_groups" "cp_secgroup" {
  name_filter = var.security_group_name
}
data "kakaocloud_key_pairs" "cp_keypair" {
  name_filter = var.key_pair_name
}

locals {
  ubuntu_image_id = [for image in data.kakaocloud_images.ubuntu.images : image.id if image.name == var.image_name][0]
  flavor_id = [for flavor in data.kakaocloud_instance_flavors.flavors.instance_flavors : flavor.id if flavor.name == var.instance_flavor][0]
  vpc_id = data.kakaocloud_vpcs.cp_network.vpcs[0].id
  subnet_id = data.kakaocloud_subnets.cp_subnet.subnets[0].id
  security_group_id = data.kakaocloud_security_groups.cp_secgroup.security_groups[0].id
  key_pair_id = data.kakaocloud_key_pairs.cp_keypair.key_pairs[0].id
}

############################################################
# Instance Resources (Master / Worker)
############################################################

resource "kakaocloud_instance" "opentofu_master_node" {
  name        = var.master_node_name
  flavor_id   = local.flavor_id
  image_id    = local.ubuntu_image_id
  key_name    = local.key_pair_id
  description = "OpenStack compatible master node"
  subnets = [{ id = local.subnet_id }]
  initial_security_groups = [{ id = local.security_group_id }]
  volumes = [{ size = var.volume_size }]
  availability_zone = var.availability_zone
  region            = var.region
  tags = { Name = var.master_node_name, Role = "master" }
  depends_on = [data.kakaocloud_vpcs.cp_network, data.kakaocloud_subnets.cp_subnet, data.kakaocloud_security_groups.cp_secgroup]
}

resource "kakaocloud_instance" "opentofu_worker_node" {
  name        = var.worker_node_name
  flavor_id   = local.flavor_id
  image_id    = local.ubuntu_image_id
  key_name    = local.key_pair_id
  description = "OpenStack compatible worker node"
  subnets = [{ id = local.subnet_id }]
  initial_security_groups = [{ id = local.security_group_id }]
  volumes = [{ size = var.volume_size }]
  availability_zone = var.availability_zone
  region            = var.region
  tags = { Name = var.worker_node_name, Role = "worker" }
  depends_on = [data.kakaocloud_vpcs.cp_network, data.kakaocloud_subnets.cp_subnet, data.kakaocloud_security_groups.cp_secgroup]
}

############################################################
# Public IPs (Floating IP 할당)
############################################################

resource "kakaocloud_public_ip" "master_floating_ip" {
  description = "Master node floating IP"
  related_resource = {
    id          = kakaocloud_instance.opentofu_master_node.addresses[0].network_interface_id
    device_id   = kakaocloud_instance.opentofu_master_node.id
    device_type = "instance"
  }
  wait_until_associated = true
  depends_on = [kakaocloud_instance.opentofu_master_node]
}

resource "kakaocloud_public_ip" "worker_floating_ip" {
  description = "Worker node floating IP"
  related_resource = {
    id          = kakaocloud_instance.opentofu_worker_node.addresses[0].network_interface_id
    device_id   = kakaocloud_instance.opentofu_worker_node.id
    device_type = "instance"
  }
  wait_until_associated = true
  depends_on = [kakaocloud_instance.opentofu_worker_node]
}

############################################################
# Outputs (호환성 유지)
############################################################

output "master_node_id" {
  description = "Master node instance ID"
  value       = kakaocloud_instance.opentofu_master_node.id
}

output "master_node_private_ip" {
  description = "Master node private IP address"
  value       = kakaocloud_instance.opentofu_master_node.addresses[0].ip_address
}

output "master_node_floating_ip" {
  description = "Master node public/floating IP address"
  value       = kakaocloud_public_ip.master_floating_ip.ip_address
}

output "worker_node_id" {
  description = "Worker node instance ID"
  value       = kakaocloud_instance.opentofu_worker_node.id
}

output "worker_node_private_ip" {
  description = "Worker node private IP address"
  value       = kakaocloud_instance.opentofu_worker_node.addresses[0].ip_address
}

output "worker_node_floating_ip" {
  description = "Worker node public/floating IP address"
  value       = kakaocloud_public_ip.worker_floating_ip.ip_address
}

output "network_id" {
  description = "Network/VPC ID"
  value       = local.vpc_id
}

output "subnet_id" {
  description = "Subnet ID"
  value       = local.subnet_id
}

output "security_group_id" {
  description = "Security group ID"
  value       = local.security_group_id
}
