# Security Module Outputs

output "security_group_id" {
  description = "Security Group ID"
  value       = kakaocloud_security_group.security_group.id
}

output "security_group_name" {
  description = "Security Group name"
  value       = kakaocloud_security_group.security_group.name
}
