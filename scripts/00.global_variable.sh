#!/usr/bin/env bash
# shellcheck disable=SC2034
# Ubuntu
export DEBIAN_FRONTEND=noninteractive

# Vagrant
export INSTALL_PATH=/home/vagrant

# VirtualBox
export VM_INTERFACE_NAME=eth1

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
