# Root Outputs - Aggregated from all modules

#####################################################################
# Network Outputs
#####################################################################
output "vpc_id" {
  description = "VPC ID"
  value       = module.network.vpc_id
}

output "subnet_id" {
  description = "Subnet ID"
  value       = module.network.subnet_id
}

#####################################################################
# Security Outputs
#####################################################################
output "security_group_id" {
  description = "Security Group ID"
  value       = module.security.security_group_id
}

#####################################################################
# Compute Outputs
#####################################################################
output "master_instance_ids" {
  description = "Master instance IDs"
  value       = module.compute.master_instance_ids
}

output "master_private_ips" {
  description = "Master instance private IPs"
  value       = module.compute.master_private_ips
}

output "master_public_ips" {
  description = "Master node public IPs"
  value       = module.compute.master_public_ips
}

output "worker_instance_ids" {
  description = "Worker instance IDs"
  value       = module.compute.worker_instance_ids
}

output "worker_private_ips" {
  description = "Worker instance private IPs"
  value       = module.compute.worker_private_ips
}

output "worker_public_ips" {
  description = "Worker node public IPs"
  value       = module.compute.worker_public_ips
}

#####################################################################
# LoadBalancer Outputs
#####################################################################
output "master_lb_id" {
  description = "Master Load Balancer ID"
  value       = module.loadbalancer.master_lb_id
}

output "master_lb_vip" {
  description = "Master Load Balancer VIP (K8s API Server)"
  value       = module.loadbalancer.master_lb_vip
}

output "master_lb_public_ip" {
  description = "Master Load Balancer Public IP (External K8s API Access)"
  value       = module.loadbalancer.master_lb_public_ip
}

output "worker_lb_id" {
  description = "Worker Load Balancer ID"
  value       = module.loadbalancer.worker_lb_id
}

output "worker_lb_vip" {
  description = "Worker Load Balancer VIP"
  value       = module.loadbalancer.worker_lb_vip
}

output "worker_lb_public_ip" {
  description = "Worker Load Balancer Public IP"
  value       = module.loadbalancer.worker_lb_public_ip
}

#####################################################################
# Kubernetes API Server Endpoints
#####################################################################
output "k8s_api_endpoints" {
  description = "Kubernetes API Server Endpoints"
  value = {
    internal = "https://${module.loadbalancer.master_lb_vip}:6443"
    external = "https://${module.loadbalancer.master_lb_public_ip}:6443"
    note     = "Internal endpoint is for cluster nodes, External endpoint is for outside access"
  }
}

#####################################################################
# K-PaaS Service Endpoints
#####################################################################
output "service_endpoints" {
  description = "K-PaaS Service Endpoints"
  value = {
    worker_lb_http  = "http://${module.loadbalancer.worker_lb_public_ip}"
    worker_lb_https = "https://${module.loadbalancer.worker_lb_public_ip}"
    portal_url      = "https://k-paas.io (Add to /etc/hosts: ${module.loadbalancer.worker_lb_public_ip} k-paas.io)"
    note            = "Worker LB provides HTTP/HTTPS access to services running on worker nodes"
  }
}

#####################################################################
# Provisioner Outputs
#####################################################################
output "provisioner_status" {
  description = "K-PaaS provisioner status"
  value       = module.provisioner.provisioner_status
}

output "generated_scripts" {
  description = "List of generated script files"
  value       = module.provisioner.generated_scripts
}
