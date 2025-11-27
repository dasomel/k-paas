# Compute Module Outputs

# Master Instances
output "master_instance_ids" {
  description = "Master instance IDs"
  value       = [for instance in kakaocloud_instance.master : instance.id]
}

output "master_private_ips" {
  description = "Master instance private IPs"
  value       = [for instance in kakaocloud_instance.master : instance.addresses[0].private_ip]
}

output "master_public_ips" {
  description = "Master node public IPs"
  value       = [for ip in kakaocloud_public_ip.master_ip : ip.public_ip]
}

output "master_instances" {
  description = "Master instance objects (for dependencies)"
  value       = kakaocloud_instance.master
}

output "master_public_ip_objects" {
  description = "Master public IP objects (for dependencies)"
  value       = kakaocloud_public_ip.master_ip
}

# Worker Instances
output "worker_instance_ids" {
  description = "Worker instance IDs"
  value       = [for instance in kakaocloud_instance.worker : instance.id]
}

output "worker_private_ips" {
  description = "Worker instance private IPs"
  value       = [for instance in kakaocloud_instance.worker : instance.addresses[0].private_ip]
}

output "worker_public_ips" {
  description = "Worker node public IPs"
  value       = [for ip in kakaocloud_public_ip.worker_ip : ip.public_ip]
}

output "worker_instances" {
  description = "Worker instance objects (for dependencies)"
  value       = kakaocloud_instance.worker
}

output "worker_public_ip_objects" {
  description = "Worker public IP objects (for dependencies)"
  value       = kakaocloud_public_ip.worker_ip
}

# Counts
output "master_count" {
  description = "Number of master nodes"
  value       = var.master_count
}

output "worker_count" {
  description = "Number of worker nodes"
  value       = var.worker_count
}
