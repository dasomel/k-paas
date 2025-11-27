#!/usr/bin/env bash
# shellcheck disable=SC2034
# Auto-generated from Terraform at deployment time

# Ubuntu
export DEBIAN_FRONTEND=noninteractive

# Install Path
export INSTALL_PATH=/home/ubuntu

# Network Interface (카카오클라우드)
export VM_INTERFACE_NAME=eth0

# ===== Terraform-generated variables =====
# NLB Configuration
export MASTER_LB_VIP=${master_lb_vip}
export MASTER_LB_PUBLIC_IP=${master_lb_public_ip}
export WORKER_LB_VIP=${worker_lb_vip}
export WORKER_LB_PUBLIC_IP=${worker_lb_public_ip}

# Master Nodes
export MASTER01=${master1_private_ip}
export MASTER02=${master2_private_ip}
export MASTER03=${master3_private_ip}
export MASTER1_NODE_PRIVATE_IP=${master1_private_ip}
export MASTER2_NODE_PRIVATE_IP=${master2_private_ip}
export MASTER3_NODE_PRIVATE_IP=${master3_private_ip}
export MASTER1_NODE_PUBLIC_IP=${master1_public_ip}
export MASTER2_NODE_PUBLIC_IP=${master2_public_ip}
export MASTER3_NODE_PUBLIC_IP=${master3_public_ip}

# Worker Nodes
export WORKER01=${worker1_private_ip}
export WORKER02=${worker2_private_ip}
export WORKER03=${worker3_private_ip}
export WORKER1_NODE_PRIVATE_IP=${worker1_private_ip}
export WORKER2_NODE_PRIVATE_IP=${worker2_private_ip}
export WORKER3_NODE_PRIVATE_IP=${worker3_private_ip}

# Cluster Endpoint (NLB VIP for K8s API Server)
export CLUSTER_ENDPOINT=${master_lb_vip}

# Portal
export PORTAL_MASTER_NODE_PUBLIC_IP=${master_lb_public_ip}
export PORTAL_HOST_IP=${ingress_nginx_ip}
export PORTAL_HOST_DOMAIN=k-paas.io
