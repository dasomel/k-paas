# Security Module - Security Group
# This module manages Security Group for K-PaaS deployment

# 보안 그룹 생성
resource "kakaocloud_security_group" "security_group" {
  name        = var.security_group_name
  description = var.description

  rules = [
    # SSH 접속
    {
      direction        = "ingress"
      protocol         = "TCP"
      port_range_min   = 22
      port_range_max   = 22
      remote_ip_prefix = "0.0.0.0/0"
      description      = "SSH 접속 허용"
    },
    # Kubernetes API Server
    {
      direction        = "ingress"
      protocol         = "TCP"
      port_range_min   = 6443
      port_range_max   = 6443
      remote_ip_prefix = "0.0.0.0/0"
      description      = "Kubernetes API Server 접근 허용"
    },
    # etcd
    {
      direction        = "ingress"
      protocol         = "TCP"
      port_range_min   = 2379
      port_range_max   = 2380
      remote_ip_prefix = var.vpc_cidr
      description      = "etcd 통신 허용 (내부망)"
    },
    # Kubelet API
    {
      direction        = "ingress"
      protocol         = "TCP"
      port_range_min   = 10250
      port_range_max   = 10250
      remote_ip_prefix = var.vpc_cidr
      description      = "Kubelet API 통신 허용 (내부망)"
    },
    # K8s Scheduler & Controller Manager
    {
      direction        = "ingress"
      protocol         = "TCP"
      port_range_min   = 10251
      port_range_max   = 10252
      remote_ip_prefix = var.vpc_cidr
      description      = "K8s Scheduler 및 Controller Manager 통신 허용 (내부망)"
    },
    # NodePort Services
    {
      direction        = "ingress"
      protocol         = "TCP"
      port_range_min   = 30000
      port_range_max   = 32767
      remote_ip_prefix = "0.0.0.0/0"
      description      = "NodePort 서비스 접근 허용"
    },
    # HTTP
    {
      direction        = "ingress"
      protocol         = "TCP"
      port_range_min   = 80
      port_range_max   = 80
      remote_ip_prefix = "0.0.0.0/0"
      description      = "HTTP 트래픽 허용"
    },
    # HTTPS
    {
      direction        = "ingress"
      protocol         = "TCP"
      port_range_min   = 443
      port_range_max   = 443
      remote_ip_prefix = "0.0.0.0/0"
      description      = "HTTPS 트래픽 허용"
    },
    # NFS rpcbind TCP
    {
      direction        = "ingress"
      protocol         = "TCP"
      port_range_min   = 111
      port_range_max   = 111
      remote_ip_prefix = var.vpc_cidr
      description      = "NFS rpcbind TCP (내부망)"
    },
    # NFS rpcbind UDP
    {
      direction        = "ingress"
      protocol         = "UDP"
      port_range_min   = 111
      port_range_max   = 111
      remote_ip_prefix = var.vpc_cidr
      description      = "NFS rpcbind UDP (내부망)"
    },
    # NFS TCP
    {
      direction        = "ingress"
      protocol         = "TCP"
      port_range_min   = 2049
      port_range_max   = 2049
      remote_ip_prefix = var.vpc_cidr
      description      = "NFS TCP (내부망)"
    },
    # NFS UDP
    {
      direction        = "ingress"
      protocol         = "UDP"
      port_range_min   = 2049
      port_range_max   = 2049
      remote_ip_prefix = var.vpc_cidr
      description      = "NFS UDP (내부망)"
    },
    # Calico VXLAN
    {
      direction        = "ingress"
      protocol         = "UDP"
      port_range_min   = 4789
      port_range_max   = 4789
      remote_ip_prefix = var.vpc_cidr
      description      = "Calico VXLAN (내부망)"
    },
    # Calico BGP
    {
      direction        = "ingress"
      protocol         = "TCP"
      port_range_min   = 179
      port_range_max   = 179
      remote_ip_prefix = var.vpc_cidr
      description      = "Calico BGP (내부망)"
    },
    # ICMP
    {
      direction        = "ingress"
      protocol         = "ICMP"
      remote_ip_prefix = "0.0.0.0/0"
      description      = "ICMP (Ping) 허용"
    },
    # All Egress
    {
      direction        = "egress"
      protocol         = "ALL"
      remote_ip_prefix = "0.0.0.0/0"
      description      = "모든 아웃바운드 트래픽 허용"
    }
  ]
}
