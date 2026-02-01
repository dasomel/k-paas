# Layer 1: Network Infrastructure
# VPC and Subnet - Created once, rarely changed

terraform {
  required_providers {
    kakaocloud = {
      source  = "kakaoenterprise/kakaocloud"
      version = "0.2.0"
    }
  }
}

provider "kakaocloud" {
  application_credential_id     = var.application_credential_id
  application_credential_secret = var.application_credential_secret
}

#####################################################################
# VPC
#####################################################################
resource "kakaocloud_vpc" "main" {
  name       = var.vpc_name
  cidr_block = var.vpc_cidr

  # VPC 내 기본 서브넷 설정 (필수)
  subnet = {
    cidr_block        = var.vpc_default_subnet_cidr
    availability_zone = var.availability_zone
  }

  lifecycle {
    prevent_destroy = true  # 실수로 삭제 방지
  }
}

#####################################################################
# Subnet
#####################################################################
resource "kakaocloud_subnet" "main" {
  vpc_id            = kakaocloud_vpc.main.id
  name              = var.subnet_name
  cidr_block        = var.subnet_cidr
  availability_zone = var.availability_zone

  lifecycle {
    prevent_destroy = true
  }
}

#####################################################################
# SSH KeyPair - 자동 생성
#####################################################################
resource "kakaocloud_keypair" "kpaas" {
  name = var.key_name

  lifecycle {
    prevent_destroy = true
  }
}

# Private Key를 로컬 파일로 저장
resource "local_sensitive_file" "private_key" {
  content         = kakaocloud_keypair.kpaas.private_key
  filename        = "${path.module}/${var.key_name}.pem"
  file_permission = "0400"
}

#####################################################################
# Outputs - 다른 레이어에서 참조
#####################################################################
output "vpc_id" {
  description = "VPC ID"
  value       = kakaocloud_vpc.main.id
}

output "vpc_cidr" {
  description = "VPC CIDR"
  value       = kakaocloud_vpc.main.cidr_block
}

output "subnet_id" {
  description = "Subnet ID"
  value       = kakaocloud_subnet.main.id
}

output "availability_zone" {
  description = "Availability Zone"
  value       = var.availability_zone
}

output "key_name" {
  description = "SSH Key Pair Name"
  value       = kakaocloud_keypair.kpaas.name
}

output "ssh_key_path" {
  description = "Path to SSH private key"
  value       = local_sensitive_file.private_key.filename
}
