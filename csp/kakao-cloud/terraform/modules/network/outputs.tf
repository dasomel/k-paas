# Network Module Outputs

output "vpc_id" {
  description = "VPC ID"
  value       = kakaocloud_vpc.kpaas_vpc.id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = kakaocloud_vpc.kpaas_vpc.cidr_block
}

output "subnet_id" {
  description = "Main subnet ID"
  value       = kakaocloud_subnet.main_subnet.id
}

output "subnet_cidr" {
  description = "Main subnet CIDR block"
  value       = kakaocloud_subnet.main_subnet.cidr_block
}

output "availability_zone" {
  description = "Availability zone"
  value       = kakaocloud_subnet.main_subnet.availability_zone
}
