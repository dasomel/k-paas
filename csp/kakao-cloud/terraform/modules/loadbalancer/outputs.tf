# LoadBalancer Module Outputs

# Master Load Balancer
output "master_lb_id" {
  description = "Master Load Balancer ID"
  value       = kakaocloud_load_balancer.master_lb.id
}

output "master_lb_vip" {
  description = "Master Load Balancer VIP (K8s API Server)"
  value       = kakaocloud_load_balancer.master_lb.private_vip
}

output "master_lb_public_ip" {
  description = "Master Load Balancer Public IP (External K8s API Access)"
  value       = kakaocloud_public_ip.master_lb_ip.public_ip
}

# Worker Load Balancer
output "worker_lb_id" {
  description = "Worker Load Balancer ID"
  value       = kakaocloud_load_balancer.worker_lb.id
}

output "worker_lb_vip" {
  description = "Worker Load Balancer VIP"
  value       = kakaocloud_load_balancer.worker_lb.private_vip
}

output "worker_lb_public_ip" {
  description = "Worker Load Balancer Public IP"
  value       = kakaocloud_public_ip.worker_lb_ip.public_ip
}

# Dependencies for other modules
output "master_lb" {
  description = "Master LB object (for dependencies)"
  value       = kakaocloud_load_balancer.master_lb
}

output "worker_lb" {
  description = "Worker LB object (for dependencies)"
  value       = kakaocloud_load_balancer.worker_lb
}
