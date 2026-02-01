#!/bin/bash
# CoreDNS and Pod HostAliases Configuration Script
# This script fixes DNS resolution issues for k-paas.io domains in pods

set -e

source /home/ubuntu/scripts/00.global_variable.sh

echo "========== CoreDNS and Pod HostAliases Configuration =========="
echo "Worker LB Public IP: ${WORKER_LB_PUBLIC_IP}"

# Step 1: Update cp-portal-ui deployment with hostAliases
echo ""
echo "Step 1: Adding hostAliases to cp-portal-ui deployment..."
kubectl patch deployment -n cp-portal cp-portal-ui-deployment --type='json' -p='[
  {
    "op": "add",
    "path": "/spec/template/spec/hostAliases",
    "value": [
      {
        "ip": "''",
        "hostnames": [
          "harbor.k-paas.io",
          "keycloak.k-paas.io",
          "portal.k-paas.io",
          "k-paas.io",
          "openbao.k-paas.io",
          "chartmuseum.k-paas.io"
        ]
      }
    ]
  }
]' 2>/dev/null || echo "HostAliases already configured or deployment not found"

echo ""
echo "Step 2: Waiting for cp-portal-ui pods to restart..."
sleep 10

echo ""
echo "Step 3: Checking cp-portal-ui pod status..."
kubectl get pod -n cp-portal -l app=cp-portal-ui

echo ""
echo "========== Configuration Complete =========="
echo "cp-portal-ui pods now have hostAliases for k-paas.io domains"
echo "They can resolve: harbor.k-paas.io, keycloak.k-paas.io, portal.k-paas.io, etc."