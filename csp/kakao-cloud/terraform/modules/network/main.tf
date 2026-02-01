# Network Module - VPC and Subnet
# This module manages VPC and Subnet resources for K-PaaS deployment

# VPC 생성 (생성시 약 5분 이상 소요)
# NOTE: Kakao Cloud provider v0.2.0 has a validation bug that prevents using
# variables for name, cidr_block, and subnet attributes. These must be hardcoded.
# This is a known provider limitation. If you need different values, edit them here.
resource "kakaocloud_vpc" "kpaas_vpc" {
  name       = "test-kpaas"
  cidr_block = "172.16.0.0/16"

  # VPC 내 기본 서브넷 설정
  subnet = {
    cidr_block        = "172.16.255.0/24"
    availability_zone = "kr-central-2-a"
  }
}

# 메인 서브넷 생성
resource "kakaocloud_subnet" "main_subnet" {
  name              = var.subnet_name
  cidr_block        = var.subnet_cidr
  availability_zone = var.availability_zone
  vpc_id            = kakaocloud_vpc.kpaas_vpc.id
}
