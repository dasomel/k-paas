#!/usr/bin/env bash
set -e
# K-PaaS Automated Installation Script for Kakao Cloud
# This script runs on Master-1 node after Terraform provisioning

echo "=========================================="
echo "K-PaaS Installation - Kakao Cloud"
echo "=========================================="

SCRIPTS_DIR="/home/ubuntu/scripts"
cd "$SCRIPTS_DIR" || exit 1

# Load global variables
if [ -f "$SCRIPTS_DIR/00.global_variable.sh" ]; then
    source "$SCRIPTS_DIR/00.global_variable.sh"
    echo "✓ Global variables loaded"
else
    echo "✗ Error: 00.global_variable.sh not found"
    exit 1
fi

# Verify essential variables
if [ -z "$CLUSTER_ENDPOINT" ]; then
    echo "✗ Error: CLUSTER_ENDPOINT not set"
    exit 1
fi

echo "Cluster Configuration:"
echo "  - NLB VIP: $CLUSTER_ENDPOINT"
echo "  - Master Nodes: $MASTER01, $MASTER02, $MASTER03"
echo "  - Worker Nodes: $WORKER01, $WORKER02, $WORKER03"
echo ""

# Step 1: Common settings for all nodes
echo "=========================================="
echo "Step 1: Common Settings"
echo "=========================================="
if [ -f "$SCRIPTS_DIR/01.all_common_setting.sh" ]; then
    bash "$SCRIPTS_DIR/01.all_common_setting.sh"
    echo "✓ Common settings completed"
else
    echo "⚠ Warning: 01.all_common_setting.sh not found, skipping..."
fi

# Step 2: NFS Server setup on Master-1
echo "=========================================="
echo "Step 2: NFS Server Setup"
echo "=========================================="
if [ -f "$SCRIPTS_DIR/03.master_nfs_server.sh" ]; then
    bash "$SCRIPTS_DIR/03.master_nfs_server.sh"
    echo "✓ NFS server setup completed"
else
    echo "✗ Error: 03.master_nfs_server.sh not found"
    exit 1
fi

# Step 3: SSH Key Distribution
echo "=========================================="
echo "Step 3: SSH Key Distribution"
echo "=========================================="
if [ -f "$SCRIPTS_DIR/04.master_ssh_setting.sh" ]; then
    bash "$SCRIPTS_DIR/04.master_ssh_setting.sh"
    echo "✓ SSH keys configured"
    echo ""
    echo "NOTE: SSH keys already distributed via Terraform provisioning"
    echo "Continuing with K-PaaS installation..."
    echo ""
    sleep 3
else
    echo "✗ Error: 04.master_ssh_setting.sh not found"
    exit 1
fi

# Step 4: K-PaaS Installation
echo "=========================================="
echo "Step 4: K-PaaS Installation"
echo "=========================================="
if [ -f "$SCRIPTS_DIR/05.master_install_k-pass.sh" ]; then
    echo "Running 05.master_install_k-pass.sh..."
    bash "$SCRIPTS_DIR/05.master_install_k-pass.sh" 2>&1 | tee -a /home/ubuntu/kpaas_install.log

    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        echo "✓ K-PaaS installation completed successfully"
    else
        echo "✗ K-PaaS installation failed"
        exit 1
    fi
else
    echo "✗ Error: 05.master_install_k-pass.sh not found"
    exit 1
fi

# Step 5: K-PaaS Portal Installation
echo ""
echo "=========================================="
echo "Step 5: K-PaaS Portal Installation"
echo "=========================================="
if [ -f "$SCRIPTS_DIR/06.master_install_k-pass_portal.sh" ]; then
    echo "Running 06.master_install_k-pass_portal.sh..."
    bash "$SCRIPTS_DIR/06.master_install_k-pass_portal.sh" 2>&1 | tee -a /home/ubuntu/portal_install.log

    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        echo "✓ K-PaaS Portal installation completed successfully"
    else
        echo "✗ K-PaaS Portal installation failed"
        echo "Check logs: /home/ubuntu/portal_install.log"
        exit 1
    fi
else
    echo "✗ Error: 06.master_install_k-pass_portal.sh not found"
    exit 1
fi

echo ""
echo "=========================================="
echo "K-PaaS + Portal Installation Completed!"
echo "=========================================="
echo ""
echo "Verification Commands:"
echo "  kubectl cluster-info"
echo "  kubectl get nodes"
echo "  kubectl get pods -A"
echo ""
echo "Access K8s API Server:"
echo "  Internal: curl -k https://$CLUSTER_ENDPOINT:6443"
echo "  External: curl -k https://$MASTER_LB_PUBLIC_IP:6443"
echo ""
echo "K-PaaS Portal Access:"
echo "  Portal URL: https://portal.k-paas.io"
echo "  Harbor URL: https://harbor.k-paas.io"
echo "  Keycloak URL: https://keycloak.k-paas.io"
echo ""
