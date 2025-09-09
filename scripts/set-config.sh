#!/usr/bin/env bash

# Check authentication information directly from the master node
CONFIG=$(vagrant ssh master01 -c "cat ~/.kube/config")

# 1. Create certificate files
echo "$CONFIG" | awk '/certificate-authority-data:/ {print $2}' | base64 -d > ca.crt
echo "$CONFIG" | awk '/client-certificate-data:/ {print $2}' | base64 -d > client.crt
echo "$CONFIG" | awk '/client-key-data:/ {print $2}' | base64 -d > client.key

# 2. Set cluster
kubectl config set-cluster k-paas \
  --server="https://cluster-endpoint:6443" \
  --certificate-authority=./ca.crt \
  --embed-certs=true

# 3. Set user
kubectl config set-credentials vagrant-user \
  --client-certificate=./client.crt \
  --client-key=./client.key \
  --embed-certs=true

# 4. Set context
kubectl config set-context k-paas \
  --cluster=k-paas \
  --user=vagrant-user

# 4. Set context (duplicate block, you may remove one)
kubectl config set-context k-paas \
  --cluster=k-paas \
  --user=vagrant-user

# 5. Activate context
kubectl config use-context k-paas

# Check if the current context is set correctly
kubectl config current-context

# Change context if necessary
kubectl config use-context vagrant

# Delete certificate files
rm ca.crt client.crt client.key

# DNS cache flush (macOS)
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder

# Check
echo "=== Current Context ==="
kubectl config current-context
echo "=== Check Nodes ==="
kubectl get nodes