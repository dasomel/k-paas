#!/bin/bash

# Master Node Count Variable (eg. 1, 3, 5 ...)
export KUBE_CONTROL_HOSTS=3

# if KUBE_CONTROL_HOSTS > 1 (eg. external, stacked)
export ETCD_TYPE=stacked

# if KUBE_CONTROL_HOSTS > 1
# HA Control Plane LoadBalanncer IP or Domain
export LOADBALANCER_DOMAIN=210.109.52.85

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
export MASTER1_NODE_PUBLIC_IP=210.109.54.150
export MASTER1_NODE_PRIVATE_IP=172.16.0.175
export MASTER2_NODE_HOSTNAME=master02
export MASTER2_NODE_PRIVATE_IP=172.16.0.123
export MASTER3_NODE_HOSTNAME=master03
export MASTER3_NODE_PRIVATE_IP=172.16.0.63

# Worker Node Count Variable
export KUBE_WORKER_HOSTS=2

# Worker Node Info Variable
# The number of Worker node variable is set equal to the number of KUBE_WORKER_HOSTS
export WORKER1_NODE_HOSTNAME=worker02
export WORKER1_NODE_PRIVATE_IP=172.16.0.203
export WORKER2_NODE_HOSTNAME=worker03
export WORKER2_NODE_PRIVATE_IP=172.16.0.45
export WORKER3_NODE_HOSTNAME=
export WORKER3_NODE_PRIVATE_IP=

# Storage Variable (eg. nfs, rook-ceph)
export STORAGE_TYPE=nfs

# if STORATE_TYPE=nfs
export NFS_SERVER_PRIVATE_IP=172.16.0.175
export NFS_EXPORT_PATH="/home/share/nfs"

# MetalLB Variable (eg. 192.168.0.150-192.168.0.160)
export METALLB_IP_RANGE=210.109.53.112-210.109.53.112

# MetalLB Ingress Nginx Controller LoadBalancer Service External IP
export INGRESS_NGINX_IP=210.109.53.112

# Install Kyverno (eg. Y, N)
# PSS(Pod Security Standards) and cp-policy(Network isolation between namespaces) implemented as Kyverno policies.
export INSTALL_KYVERNO=Y