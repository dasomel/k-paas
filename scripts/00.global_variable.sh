#!/usr/bin/env bash
# shellcheck disable=SC2034
# Ubuntu
export DEBIAN_FRONTEND=noninteractive

# Vagrant
export INSTALL_PATH=/home/vagrant

# Network Interface (auto-detect based on private network IP range 192.168.100.x)
# Works for both VirtualBox (eth1) and VMware (ens160, enp26s0, etc.)
export VM_INTERFACE_NAME=$(ip -o -4 addr show | grep '192\.168\.100\.' | awk '{print $2}' | head -1)
# Fallback to eth1 if detection fails
[ -z "$VM_INTERFACE_NAME" ] && export VM_INTERFACE_NAME=eth1

# Node
export LB01=192.168.100.121
export LB02=192.168.100.122
export MASTER01=192.168.100.101
export MASTER02=192.168.100.102
export WORKER01=192.168.100.111
export WORKER02=192.168.100.112
export CLUSTER_ENDPOINT=192.168.100.200

# Portal
export PORTAL_MASTER_NODE_PUBLIC_IP=cluster-endpoint
export PORTAL_HOST_IP=192.168.100.201
export PORTAL_HOST_DOMAIN=k-paas.io

# Cluster Configuration
export KUBE_CONTROL_HOSTS=2
export KUBE_WORKER_HOSTS=2
export ETCD_TYPE=stacked
export STORAGE_TYPE=nfs
export METALLB_IP_RANGE=192.168.100.210-192.168.100.250
export INSTALL_KYVERNO=Y

# CSP (Cloud Service Provider) - leave empty for local/bare-metal
export CSP_TYPE=
