# Layer 2: Load Balancer Infrastructure
# Security Group + Master LB + Worker LB - Created once with fixed IP targets

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
# Remote State - Network Layer 참조
#####################################################################
data "terraform_remote_state" "network" {
  backend = "local"
  config = {
    path = "../01-network/terraform.tfstate"
  }
}

locals {
  subnet_id         = data.terraform_remote_state.network.outputs.subnet_id
  availability_zone = data.terraform_remote_state.network.outputs.availability_zone
  vpc_cidr          = data.terraform_remote_state.network.outputs.vpc_cidr
}

#####################################################################
# Data Source - Load Balancer Flavors
#####################################################################
data "kakaocloud_load_balancer_flavors" "all" {}

locals {
  lb_flavor_nlb_id = [
    for flavor in data.kakaocloud_load_balancer_flavors.all.flavors : flavor.id
    if flavor.name == "NLB"
  ][0]
}

#####################################################################
# Security Group (with inline rules)
#####################################################################
resource "kakaocloud_security_group" "kpaas" {
  name        = var.security_group_name
  description = "K-PaaS Security Group"

  rules = [
    # SSH
    {
      direction        = "ingress"
      protocol         = "TCP"
      port_range_min   = 22
      port_range_max   = 22
      remote_ip_prefix = "0.0.0.0/0"
      description      = "SSH"
    },
    # HTTP
    {
      direction        = "ingress"
      protocol         = "TCP"
      port_range_min   = 80
      port_range_max   = 80
      remote_ip_prefix = "0.0.0.0/0"
      description      = "HTTP"
    },
    # HTTPS
    {
      direction        = "ingress"
      protocol         = "TCP"
      port_range_min   = 443
      port_range_max   = 443
      remote_ip_prefix = "0.0.0.0/0"
      description      = "HTTPS"
    },
    # K8s API Server
    {
      direction        = "ingress"
      protocol         = "TCP"
      port_range_min   = 6443
      port_range_max   = 6443
      remote_ip_prefix = "0.0.0.0/0"
      description      = "Kubernetes API Server"
    },
    # etcd
    {
      direction        = "ingress"
      protocol         = "TCP"
      port_range_min   = 2379
      port_range_max   = 2380
      remote_ip_prefix = local.vpc_cidr
      description      = "etcd"
    },
    # Kubelet API
    {
      direction        = "ingress"
      protocol         = "TCP"
      port_range_min   = 10250
      port_range_max   = 10250
      remote_ip_prefix = local.vpc_cidr
      description      = "Kubelet API"
    },
    # K8s Scheduler & Controller Manager
    {
      direction        = "ingress"
      protocol         = "TCP"
      port_range_min   = 10251
      port_range_max   = 10252
      remote_ip_prefix = local.vpc_cidr
      description      = "K8s Scheduler & Controller Manager"
    },
    # NodePort Services
    {
      direction        = "ingress"
      protocol         = "TCP"
      port_range_min   = 30000
      port_range_max   = 32767
      remote_ip_prefix = "0.0.0.0/0"
      description      = "NodePort Services"
    },
    # NFS rpcbind TCP
    {
      direction        = "ingress"
      protocol         = "TCP"
      port_range_min   = 111
      port_range_max   = 111
      remote_ip_prefix = local.vpc_cidr
      description      = "NFS rpcbind TCP"
    },
    # NFS rpcbind UDP
    {
      direction        = "ingress"
      protocol         = "UDP"
      port_range_min   = 111
      port_range_max   = 111
      remote_ip_prefix = local.vpc_cidr
      description      = "NFS rpcbind UDP"
    },
    # NFS TCP
    {
      direction        = "ingress"
      protocol         = "TCP"
      port_range_min   = 2049
      port_range_max   = 2049
      remote_ip_prefix = local.vpc_cidr
      description      = "NFS TCP"
    },
    # NFS UDP
    {
      direction        = "ingress"
      protocol         = "UDP"
      port_range_min   = 2049
      port_range_max   = 2049
      remote_ip_prefix = local.vpc_cidr
      description      = "NFS UDP"
    },
    # Calico VXLAN
    {
      direction        = "ingress"
      protocol         = "UDP"
      port_range_min   = 4789
      port_range_max   = 4789
      remote_ip_prefix = local.vpc_cidr
      description      = "Calico VXLAN"
    },
    # Calico BGP
    {
      direction        = "ingress"
      protocol         = "TCP"
      port_range_min   = 179
      port_range_max   = 179
      remote_ip_prefix = local.vpc_cidr
      description      = "Calico BGP"
    },
    # ICMP
    {
      direction        = "ingress"
      protocol         = "ICMP"
      remote_ip_prefix = "0.0.0.0/0"
      description      = "ICMP (Ping)"
    },
    # All Egress
    {
      direction        = "egress"
      protocol         = "ALL"
      remote_ip_prefix = "0.0.0.0/0"
      description      = "All Egress"
    }
  ]
}

#####################################################################
# Master Load Balancer (K8s API Server)
#####################################################################
resource "kakaocloud_load_balancer" "master" {
  name              = var.master_lb_name
  description       = "Load Balancer for K8s API Server"
  availability_zone = local.availability_zone
  subnet_id         = local.subnet_id
  flavor_id         = local.lb_flavor_nlb_id
}

resource "kakaocloud_public_ip" "master_lb" {
  description = "Public IP for master LB"
  related_resource = {
    device_id   = kakaocloud_load_balancer.master.id
    device_type = "load-balancer"
  }
  depends_on = [kakaocloud_load_balancer.master]
}

# K8s API Server Listener (TCP 6443)
resource "kakaocloud_load_balancer_listener" "k8s_api" {
  load_balancer_id = kakaocloud_load_balancer.master.id
  protocol         = "TCP"
  protocol_port    = 6443
  connection_limit = -1
}

# etcd Listener (TCP 2379)
resource "kakaocloud_load_balancer_listener" "etcd" {
  load_balancer_id = kakaocloud_load_balancer.master.id
  protocol         = "TCP"
  protocol_port    = 2379
  connection_limit = -1
}

# Master Target Group for K8s API
resource "kakaocloud_load_balancer_target_group" "masters" {
  name                    = "masters-tg"
  description             = "Target group for K8s API Server"
  load_balancer_id        = kakaocloud_load_balancer.master.id
  listener_id             = kakaocloud_load_balancer_listener.k8s_api.id
  protocol                = "TCP"
  load_balancer_algorithm = "ROUND_ROBIN"
}

# etcd Target Group
resource "kakaocloud_load_balancer_target_group" "etcd" {
  name                    = "etcd-tg"
  description             = "Target group for etcd"
  load_balancer_id        = kakaocloud_load_balancer.master.id
  listener_id             = kakaocloud_load_balancer_listener.etcd.id
  protocol                = "TCP"
  load_balancer_algorithm = "ROUND_ROBIN"
}

# Master Target Group Members (K8s API) - Fixed IPs
resource "kakaocloud_load_balancer_target_group_member" "master_members" {
  for_each        = { for i, ip in var.master_private_ips : i => ip }
  target_group_id = kakaocloud_load_balancer_target_group.masters.id
  address         = each.value
  subnet_id       = local.subnet_id
  protocol_port   = 6443
  weight          = 1
}

# etcd Target Group Members - Fixed IPs
resource "kakaocloud_load_balancer_target_group_member" "etcd_members" {
  for_each        = { for i, ip in var.master_private_ips : i => ip }
  target_group_id = kakaocloud_load_balancer_target_group.etcd.id
  address         = each.value
  subnet_id       = local.subnet_id
  protocol_port   = 2379
  weight          = 1
}

#####################################################################
# Worker Load Balancer (Ingress)
#####################################################################
resource "kakaocloud_load_balancer" "worker" {
  name              = var.worker_lb_name
  description       = "Load Balancer for K8s worker nodes"
  availability_zone = local.availability_zone
  subnet_id         = local.subnet_id
  flavor_id         = local.lb_flavor_nlb_id
}

resource "kakaocloud_public_ip" "worker_lb" {
  description = "Public IP for worker LB"
  related_resource = {
    device_id   = kakaocloud_load_balancer.worker.id
    device_type = "load-balancer"
  }
  depends_on = [kakaocloud_load_balancer.worker]
}

# HTTP Listener (TCP 80)
resource "kakaocloud_load_balancer_listener" "http" {
  load_balancer_id = kakaocloud_load_balancer.worker.id
  protocol         = "TCP"
  protocol_port    = 80
  connection_limit = -1
}

# HTTPS Listener (TCP 443)
resource "kakaocloud_load_balancer_listener" "https" {
  load_balancer_id = kakaocloud_load_balancer.worker.id
  protocol         = "TCP"
  protocol_port    = 443
  connection_limit = -1
}

# Worker Target Group (HTTP)
resource "kakaocloud_load_balancer_target_group" "workers_http" {
  name                    = "workers-http-tg"
  description             = "Target group for worker nodes HTTP"
  load_balancer_id        = kakaocloud_load_balancer.worker.id
  listener_id             = kakaocloud_load_balancer_listener.http.id
  protocol                = "TCP"
  load_balancer_algorithm = "ROUND_ROBIN"
}

# Worker Target Group (HTTPS)
resource "kakaocloud_load_balancer_target_group" "workers_https" {
  name                    = "workers-https-tg"
  description             = "Target group for worker nodes HTTPS"
  load_balancer_id        = kakaocloud_load_balancer.worker.id
  listener_id             = kakaocloud_load_balancer_listener.https.id
  protocol                = "TCP"
  load_balancer_algorithm = "ROUND_ROBIN"
}

# Worker Target Group Members (HTTP) - Fixed IPs -> NodePort 31080
resource "kakaocloud_load_balancer_target_group_member" "worker_http_members" {
  for_each        = { for i, ip in var.worker_private_ips : i => ip }
  target_group_id = kakaocloud_load_balancer_target_group.workers_http.id
  address         = each.value
  subnet_id       = local.subnet_id
  protocol_port   = 31080
  weight          = 1
}

# Worker Target Group Members (HTTPS) - Fixed IPs -> NodePort 31443
resource "kakaocloud_load_balancer_target_group_member" "worker_https_members" {
  for_each        = { for i, ip in var.worker_private_ips : i => ip }
  target_group_id = kakaocloud_load_balancer_target_group.workers_https.id
  address         = each.value
  subnet_id       = local.subnet_id
  protocol_port   = 31443
  weight          = 1
}

#####################################################################
# Outputs
#####################################################################
output "security_group_id" {
  description = "Security Group ID"
  value       = kakaocloud_security_group.kpaas.id
}

output "security_group_name" {
  description = "Security Group Name"
  value       = kakaocloud_security_group.kpaas.name
}

output "master_lb_id" {
  description = "Master LB ID"
  value       = kakaocloud_load_balancer.master.id
}

output "master_lb_vip" {
  description = "Master LB VIP (Private)"
  value       = kakaocloud_load_balancer.master.private_vip
}

output "master_lb_public_ip" {
  description = "Master LB Public IP"
  value       = kakaocloud_public_ip.master_lb.public_ip
}

output "worker_lb_id" {
  description = "Worker LB ID"
  value       = kakaocloud_load_balancer.worker.id
}

output "worker_lb_vip" {
  description = "Worker LB VIP (Private)"
  value       = kakaocloud_load_balancer.worker.private_vip
}

output "worker_lb_public_ip" {
  description = "Worker LB Public IP"
  value       = kakaocloud_public_ip.worker_lb.public_ip
}

output "master_private_ips" {
  description = "Master node fixed private IPs"
  value       = var.master_private_ips
}

output "worker_private_ips" {
  description = "Worker node fixed private IPs"
  value       = var.worker_private_ips
}
