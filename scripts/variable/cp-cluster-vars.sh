#!/bin/bash

# Master Node Count Variable (eg. 1, 3, 5 ...)
export KUBE_CONTROL_HOSTS=2

# if KUBE_CONTROL_HOSTS > 1 (eg. external, stacked)
export ETCD_TYPE=stacked

# if KUBE_CONTROL_HOSTS > 1
# HA Control Plane LoadBalanncer IP or Domain
export LOADBALANCER_DOMAIN=cluster-endpoint

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
export MASTER1_NODE_PUBLIC_IP=192.168.100.101
export MASTER1_NODE_PRIVATE_IP=192.168.100.101
export MASTER2_NODE_HOSTNAME=master02
export MASTER2_NODE_PRIVATE_IP=192.168.100.102
export MASTER3_NODE_HOSTNAME=
export MASTER3_NODE_PRIVATE_IP=

# Worker Node Count Variable
export KUBE_WORKER_HOSTS=2

# Worker Node Info Variable
# The number of Worker node variable is set equal to the number of KUBE_WORKER_HOSTS
export WORKER1_NODE_HOSTNAME=worker01
export WORKER1_NODE_PRIVATE_IP=192.168.100.111
export WORKER2_NODE_HOSTNAME=worker02
export WORKER2_NODE_PRIVATE_IP=192.168.100.112
export WORKER3_NODE_HOSTNAME=
export WORKER3_NODE_PRIVATE_IP=

# Storage Variable (eg. nfs, rook-ceph)
export STORAGE_TYPE=nfs

# if STORATE_TYPE=nfs
export NFS_SERVER_PRIVATE_IP=192.168.100.101

# MetalLB Variable (eg. 192.168.0.150-192.168.0.160)
export METALLB_IP_RANGE=192.168.100.210-192.168.100.250

# MetalLB Ingress Nginx Controller LoadBalancer Service External IP
export INGRESS_NGINX_IP=192.168.100.201

# Install Kyverno (eg. Y, N)
# PSS(Pod Security Standards) and cp-policy(Network isolation between namespaces) implemented as Kyverno policies.
export INSTALL_KYVERNO=Y