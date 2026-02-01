# LoadBalancer Module - Master and Worker Load Balancers
# This module manages Load Balancers for K8s API Server and Worker nodes

# Data source for LB flavors
data "kakaocloud_load_balancer_flavors" "load_balancer_flavors_all" {}

locals {
  lb_flavor_nlb_id = [
    for lb_flavor in data.kakaocloud_load_balancer_flavors.load_balancer_flavors_all.flavors : lb_flavor.id
    if lb_flavor.name == "NLB"
  ][0]
}

#####################################################################
# Master Load Balancer (K8s API Server)
#####################################################################

resource "kakaocloud_load_balancer" "master_lb" {
  name              = var.master_lb_name
  description       = "Load Balancer for K8s API Server"
  availability_zone = var.availability_zone
  subnet_id         = var.subnet_id
  flavor_id         = local.lb_flavor_nlb_id

  # depends_on removed to allow parallel creation

}

resource "kakaocloud_public_ip" "master_lb_ip" {
  description = "Public IP for master LB"
  related_resource = {
    device_id   = kakaocloud_load_balancer.master_lb.id
    device_type = "load-balancer"
  }
  depends_on = [kakaocloud_load_balancer.master_lb]
}

# K8s API Server Listener (TCP 6443)
resource "kakaocloud_load_balancer_listener" "k8s_api" {
  load_balancer_id = kakaocloud_load_balancer.master_lb.id
  protocol         = "TCP"
  protocol_port    = 6443
  connection_limit = -1
}

# etcd Listener (TCP 2379)
resource "kakaocloud_load_balancer_listener" "etcd" {
  load_balancer_id = kakaocloud_load_balancer.master_lb.id
  protocol         = "TCP"
  protocol_port    = 2379
  connection_limit = -1
}

# Master Target Group for K8s API
resource "kakaocloud_load_balancer_target_group" "masters" {
  name                    = "masters-tg"
  description             = "Target group for K8s API Server"
  load_balancer_id        = kakaocloud_load_balancer.master_lb.id
  listener_id             = kakaocloud_load_balancer_listener.k8s_api.id
  protocol                = "TCP"
  load_balancer_algorithm = "ROUND_ROBIN"
}

# etcd Target Group
resource "kakaocloud_load_balancer_target_group" "etcd" {
  name                    = "etcd-tg"
  description             = "Target group for etcd"
  load_balancer_id        = kakaocloud_load_balancer.master_lb.id
  listener_id             = kakaocloud_load_balancer_listener.etcd.id
  protocol                = "TCP"
  load_balancer_algorithm = "ROUND_ROBIN"
}

# Master Target Group Members (K8s API)
resource "kakaocloud_load_balancer_target_group_member" "master_members" {
  for_each        = { for i, ip in var.master_private_ips : i => ip }
  target_group_id = kakaocloud_load_balancer_target_group.masters.id
  address         = each.value
  subnet_id       = var.subnet_id
  protocol_port   = 6443
  weight          = 1
}

# etcd Target Group Members
resource "kakaocloud_load_balancer_target_group_member" "etcd_members" {
  for_each        = { for i, ip in var.master_private_ips : i => ip }
  target_group_id = kakaocloud_load_balancer_target_group.etcd.id
  address         = each.value
  subnet_id       = var.subnet_id
  protocol_port   = 2379
  weight          = 1
}

#####################################################################
# Worker Load Balancer (Ingress)
#####################################################################

resource "kakaocloud_load_balancer" "worker_lb" {
  name              = var.worker_lb_name
  description       = "Load Balancer for K8s worker nodes"
  availability_zone = var.availability_zone
  subnet_id         = var.subnet_id
  flavor_id         = local.lb_flavor_nlb_id

  # depends_on removed to allow parallel creation

}

resource "kakaocloud_public_ip" "worker_lb_ip" {
  description = "Public IP for worker LB"
  related_resource = {
    device_id   = kakaocloud_load_balancer.worker_lb.id
    device_type = "load-balancer"
  }
  depends_on = [kakaocloud_load_balancer.worker_lb]
}

# HTTP Listener (TCP 80)
resource "kakaocloud_load_balancer_listener" "http" {
  load_balancer_id = kakaocloud_load_balancer.worker_lb.id
  protocol         = "TCP"
  protocol_port    = 80
  connection_limit = -1
}

# HTTPS Listener (TCP 443)
resource "kakaocloud_load_balancer_listener" "https" {
  load_balancer_id = kakaocloud_load_balancer.worker_lb.id
  protocol         = "TCP"
  protocol_port    = 443
  connection_limit = -1
}

# Worker Target Group (HTTP)
resource "kakaocloud_load_balancer_target_group" "workers_http" {
  name                    = "workers-http-tg"
  description             = "Target group for worker nodes HTTP"
  load_balancer_id        = kakaocloud_load_balancer.worker_lb.id
  listener_id             = kakaocloud_load_balancer_listener.http.id
  protocol                = "TCP"
  load_balancer_algorithm = "ROUND_ROBIN"
}

# Worker Target Group (HTTPS)
resource "kakaocloud_load_balancer_target_group" "workers_https" {
  name                    = "workers-https-tg"
  description             = "Target group for worker nodes HTTPS"
  load_balancer_id        = kakaocloud_load_balancer.worker_lb.id
  listener_id             = kakaocloud_load_balancer_listener.https.id
  protocol                = "TCP"
  load_balancer_algorithm = "ROUND_ROBIN"
}

# Worker Target Group Members (HTTP)
resource "kakaocloud_load_balancer_target_group_member" "worker_http_members" {
  for_each        = { for i, ip in var.worker_private_ips : i => ip }
  target_group_id = kakaocloud_load_balancer_target_group.workers_http.id
  address         = each.value
  subnet_id       = var.subnet_id
  protocol_port   = 31080
  weight          = 1
}

# Worker Target Group Members (HTTPS)
resource "kakaocloud_load_balancer_target_group_member" "worker_https_members" {
  for_each        = { for i, ip in var.worker_private_ips : i => ip }
  target_group_id = kakaocloud_load_balancer_target_group.workers_https.id
  address         = each.value
  subnet_id       = var.subnet_id
  protocol_port   = 31443
  weight          = 1
}
