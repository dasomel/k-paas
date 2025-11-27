#!/bin/bash
# Auto-generated from Terraform at deployment time
# Terraform project: ${terraform_dir}

# Master Node Count Variable (eg. 1, 3, 5 ...)
export KUBE_CONTROL_HOSTS=${master_count}

# if KUBE_CONTROL_HOSTS > 1 (eg. external, stacked)
export ETCD_TYPE=stacked

# if KUBE_CONTROL_HOSTS > 1
# HA Control Plane LoadBalancer IP or Domain
# NLB VIP (Private IP): ${master_lb_vip}
# NLB Public IP: ${master_lb_public_ip}
export LOADBALANCER_DOMAIN=${master_lb_vip}

# if ETCD_TYPE=external
# The number of ETCD node variable is set equal to the number of KUBE_CONTROL_HOSTS
export ETCD1_NODE_HOSTNAME=
export ETCD1_NODE_PRIVATE_IP=
export ETCD2_NODE_HOSTNAME=
export ETCD2_NODE_PRIVATE_IP=
export ETCD3_NODE_HOSTNAME=
export ETCD3_NODE_PRIVATE_IP=

# Master Node Info Variable
# The number of MASTER node variable is set equal to the number of KUBE_CONTROL_HOSTS
export MASTER1_NODE_HOSTNAME=master01
export MASTER1_NODE_PUBLIC_IP=${master1_public_ip}
export MASTER1_NODE_PRIVATE_IP=${master1_private_ip}
export MASTER2_NODE_HOSTNAME=master02
export MASTER2_NODE_PRIVATE_IP=${master2_private_ip}
export MASTER3_NODE_HOSTNAME=master03
export MASTER3_NODE_PRIVATE_IP=${master3_private_ip}

# Worker Node Count Variable
export KUBE_WORKER_HOSTS=${worker_count}

# Worker Node Info Variable
# The number of Worker node variable is set equal to the number of KUBE_WORKER_HOSTS
export WORKER1_NODE_HOSTNAME=worker01
export WORKER1_NODE_PRIVATE_IP=${worker1_private_ip}
export WORKER2_NODE_HOSTNAME=worker02
export WORKER2_NODE_PRIVATE_IP=${worker2_private_ip}
export WORKER3_NODE_HOSTNAME=worker03
export WORKER3_NODE_PRIVATE_IP=${worker3_private_ip}

# Storage Variable (eg. nfs, rook-ceph)
export STORAGE_TYPE=nfs

# if STORATE_TYPE=nfs
export NFS_SERVER_PRIVATE_IP=${master1_private_ip}

# MetalLB Variable (eg. 192.168.0.150-192.168.0.160)
export METALLB_IP_RANGE=${metallb_ip_range}

# MetalLB Ingress Nginx Controller LoadBalancer Service External IP
export INGRESS_NGINX_IP=${ingress_nginx_ip}

# Install Kyverno (eg. Y, N)
# PSS(Pod Security Standards) and cp-policy(Network isolation between namespaces) implemented as Kyverno policies.
export INSTALL_KYVERNO=Y
