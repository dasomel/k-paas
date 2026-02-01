# K-PaaS Post-Installation Script Templates

This document contains script templates that were created for the previous cluster deployment and can be adapted for new deployments.

## Script Structure

All post-installation fix scripts follow this pattern:

```bash
#!/bin/bash
# Script Name and Purpose
set -e  # Exit on error

# Source global variables
source /home/ubuntu/scripts/00.global_variable.sh

# Script logic here
# ...

echo "========== Script completed successfully =========="
```

---

## Template 1: Harbor Certificate Configuration (07.fix_harbor_certificate.sh)

```bash
#!/bin/bash
# Harbor Certificate Configuration Script
# Configures Harbor's self-signed certificate on all worker nodes
set -e

source /home/ubuntu/scripts/00.global_variable.sh

echo "========== Starting Harbor Certificate Configuration =========="

# Step 1: Download Harbor certificate from master-1
echo "Step 1: Downloading Harbor certificate from master-1..."
ssh -o StrictHostKeyChecking=no ubuntu@master01 << 'EOF'
echo | openssl s_client -showcerts -connect harbor.k-paas.io:443 2>/dev/null | \
    sed -n '/BEGIN CERTIFICATE/,/END CERTIFICATE/p' > /tmp/harbor-ca.crt
EOF

# Step 2: Copy certificate to all worker nodes
echo "Step 2: Distributing certificate to worker nodes..."
for i in $(seq 1 ${WORKER_COUNT}); do
    WORKER_HOST="worker0${i}"
    echo "Processing ${WORKER_HOST}..."

    scp -o StrictHostKeyChecking=no master01:/tmp/harbor-ca.crt /tmp/harbor-ca.crt
    scp -o StrictHostKeyChecking=no /tmp/harbor-ca.crt ubuntu@${WORKER_HOST}:/tmp/harbor-ca.crt
done

# Step 3: Configure certificate on each worker
echo "Step 3: Configuring certificate and CRI-O on workers..."
for i in $(seq 1 ${WORKER_COUNT}); do
    WORKER_HOST="worker0${i}"
    echo "Configuring ${WORKER_HOST}..."

    ssh -o StrictHostKeyChecking=no ubuntu@${WORKER_HOST} << 'WORKEREOF'
        # Install certificate to system CA trust store
        sudo mkdir -p /usr/local/share/ca-certificates/harbor
        sudo cp /tmp/harbor-ca.crt /usr/local/share/ca-certificates/harbor/harbor.crt
        sudo update-ca-certificates

        # Configure CRI-O to trust Harbor registry
        sudo mkdir -p /etc/containers/certs.d/harbor.k-paas.io
        sudo cp /tmp/harbor-ca.crt /etc/containers/certs.d/harbor.k-paas.io/ca.crt

        # Create CRI-O registry configuration
        sudo tee /etc/containers/registries.conf.d/harbor.conf > /dev/null << 'EOF'
[[registry]]
location = "harbor.k-paas.io"
insecure = false
EOF

        # Restart CRI-O to apply changes
        sudo systemctl restart crio

        # Verify CRI-O status
        sudo systemctl is-active crio
WORKEREOF
done

echo "========== Harbor Certificate Configuration Completed =========="
```

---

## Template 2: Pod DNS Resolution Fix (08.fix_coredns_hostaliases.sh)

```bash
#!/bin/bash
# CoreDNS and Pod HostAliases Configuration Script
# Fixes DNS resolution for k-paas.io domains in pods
set -e

source /home/ubuntu/scripts/00.global_variable.sh

echo "========== Starting DNS Resolution Fix =========="

# Step 1: Patch cp-portal-ui deployment with hostAliases
echo "Step 1: Patching cp-portal-ui deployment with hostAliases..."
kubectl patch deployment -n cp-portal cp-portal-ui-deployment --type='json' -p='[
  {
    "op": "add",
    "path": "/spec/template/spec/hostAliases",
    "value": [
      {
        "ip": "'${WORKER_LB_PUBLIC_IP}'",
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
]'

# Step 2: Delete existing pods to trigger recreation
echo "Step 2: Deleting existing pods to apply changes..."
kubectl delete pod -n cp-portal -l app=cp-portal-ui-deployment

# Step 3: Wait for pods to be ready
echo "Step 3: Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod -n cp-portal -l app=cp-portal-ui-deployment --timeout=300s

# Step 4: Verify hostAliases
echo "Step 4: Verifying hostAliases configuration..."
kubectl get deployment -n cp-portal cp-portal-ui-deployment -o jsonpath='{.spec.template.spec.hostAliases}' | jq .

echo "========== DNS Resolution Fix Completed =========="
```

---

## Template 3: API Server Certificate Regeneration (09.regenerate_apiserver_certificate.sh)

```bash
#!/bin/bash
# API Server Certificate Regeneration Script
# Regenerates API server certificates with Master LB Public IP
set -e

source /home/ubuntu/scripts/00.global_variable.sh

echo "========== Starting API Server Certificate Regeneration =========="

# Create OpenSSL configuration with all SANs
echo "Step 1: Creating OpenSSL configuration..."
cat > /tmp/apiserver-san.cnf << EOF
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name

[req_distinguished_name]

[v3_req]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = kubernetes
DNS.2 = kubernetes.default
DNS.3 = kubernetes.default.svc
DNS.4 = kubernetes.default.svc.cluster.local
DNS.5 = master01
DNS.6 = master02
DNS.7 = master03
DNS.8 = cluster-endpoint
IP.1 = 10.233.0.1
IP.2 = ${MASTER01_PRIVATE_IP}
IP.3 = ${MASTER02_PRIVATE_IP}
IP.4 = ${MASTER03_PRIVATE_IP}
IP.5 = 127.0.0.1
IP.6 = ::1
IP.7 = ${MASTER_LB_PRIVATE_IP}
IP.8 = ${MASTER_LB_PUBLIC_IP}
EOF

# Process each master node
for i in $(seq 1 ${MASTER_COUNT}); do
    MASTER_HOST="master0${i}"
    echo "========== Processing ${MASTER_HOST} =========="

    # Copy OpenSSL config to master
    scp -o StrictHostKeyChecking=no /tmp/apiserver-san.cnf ubuntu@${MASTER_HOST}:/tmp/apiserver-san.cnf

    # Regenerate certificate on master node
    ssh -o StrictHostKeyChecking=no ubuntu@${MASTER_HOST} << 'EOF'
        echo "Generating new certificate..."

        # Generate CSR with new SANs
        sudo openssl req -new -key /etc/kubernetes/ssl/apiserver.key \
            -out /tmp/apiserver.csr \
            -subj "/CN=kube-apiserver" \
            -config /tmp/apiserver-san.cnf

        # Sign CSR with cluster CA
        sudo openssl x509 -req -in /tmp/apiserver.csr \
            -CA /etc/kubernetes/ssl/ca.crt \
            -CAkey /etc/kubernetes/ssl/ca.key \
            -CAcreateserial \
            -out /tmp/apiserver-new.crt \
            -days 3650 \
            -extensions v3_req \
            -extfile /tmp/apiserver-san.cnf

        # Backup old certificate
        sudo cp /etc/kubernetes/ssl/apiserver.crt /etc/kubernetes/ssl/apiserver.crt.bak

        # Replace certificate
        sudo mv /tmp/apiserver-new.crt /etc/kubernetes/ssl/apiserver.crt

        # Restart API server by temporarily moving manifest
        sudo mv /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/kube-apiserver.yaml.tmp
        sleep 5
        sudo mv /tmp/kube-apiserver.yaml.tmp /etc/kubernetes/manifests/kube-apiserver.yaml

        echo "Certificate regenerated successfully"
EOF

    echo "${MASTER_HOST} completed"
    sleep 10
done

# Verify API server pods
echo "Verifying API server pods..."
sleep 30
kubectl get pods -n kube-system | grep kube-apiserver

echo "========== API Server Certificate Regeneration Completed =========="
```

---

## Template 4: Master Orchestration Script (10.post_install_fixes.sh)

```bash
#!/bin/bash
# K-PaaS Post-Installation Fixes Script
# Master orchestration script that runs all post-installation fixes
set -e

SCRIPT_DIR="/home/ubuntu/scripts"
source ${SCRIPT_DIR}/00.global_variable.sh

echo "=========================================="
echo "K-PaaS Post-Installation Fixes"
echo "=========================================="
echo ""
echo "This script will apply the following fixes:"
echo "1. Harbor certificate configuration for CRI-O"
echo "2. Pod DNS resolution using hostAliases"
echo "3. API server certificate regeneration"
echo ""
echo "Cluster Information:"
echo "- Master LB Public IP: ${MASTER_LB_PUBLIC_IP}"
echo "- Worker LB Public IP: ${WORKER_LB_PUBLIC_IP}"
echo "- Master Count: ${MASTER_COUNT}"
echo "- Worker Count: ${WORKER_COUNT}"
echo ""
read -p "Continue? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Aborted by user"
    exit 1
fi

echo ""
echo "========== Step 1: Harbor Certificate Configuration =========="
bash ${SCRIPT_DIR}/07.fix_harbor_certificate.sh

echo ""
echo "========== Step 2: Pod DNS Resolution Fix =========="
bash ${SCRIPT_DIR}/08.fix_coredns_hostaliases.sh

echo ""
echo "========== Step 3: API Server Certificate Regeneration =========="
bash ${SCRIPT_DIR}/09.regenerate_apiserver_certificate.sh

echo ""
echo "=========================================="
echo "All post-installation fixes completed!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Verify external access: kubectl --kubeconfig=/tmp/kpaas-external-kubeconfig.yaml get nodes"
echo "2. Check cp-portal pods: kubectl get pods -n cp-portal"
echo "3. Verify Harbor access: docker pull harbor.k-paas.io/library/nginx:latest"
echo ""
```

---

## Global Variables Template (00.global_variable.sh)

```bash
#!/bin/bash
# Global variables for K-PaaS cluster configuration

# Master Nodes
export MASTER_COUNT=3
export MASTER01_PRIVATE_IP="172.16.0.xxx"  # Update with actual IP
export MASTER02_PRIVATE_IP="172.16.0.xxx"  # Update with actual IP
export MASTER03_PRIVATE_IP="172.16.0.xxx"  # Update with actual IP

# Worker Nodes
export WORKER_COUNT=3
export WORKER01_PRIVATE_IP="172.16.0.xxx"  # Update with actual IP
export WORKER02_PRIVATE_IP="172.16.0.xxx"  # Update with actual IP
export WORKER03_PRIVATE_IP="172.16.0.xxx"  # Update with actual IP

# Load Balancers
export MASTER_LB_PUBLIC_IP="210.109.xx.xx"   # Update with actual IP
export MASTER_LB_PRIVATE_IP="172.16.0.xxx"   # Update with actual IP
export WORKER_LB_PUBLIC_IP="210.109.xx.xx"   # Update with actual IP
export WORKER_LB_PRIVATE_IP="172.16.0.xxx"   # Update with actual IP

# Domain Configuration
export PORTAL_DOMAIN="k-paas.io"

# Kubernetes Configuration
export KUBERNETES_SERVICE_IP="10.233.0.1"
export API_SERVER_MANIFEST="/etc/kubernetes/manifests/kube-apiserver.yaml"

# Paths
export SCRIPTS_DIR="/home/ubuntu/scripts"
export KUBECONFIG="/home/ubuntu/.kube/config"

echo "Global variables loaded:"
echo "- Master LB Public IP: ${MASTER_LB_PUBLIC_IP}"
echo "- Worker LB Public IP: ${WORKER_LB_PUBLIC_IP}"
echo "- Master Count: ${MASTER_COUNT}"
echo "- Worker Count: ${WORKER_COUNT}"
```

---

## Usage Instructions

### For New Cluster Deployment

1. **Update global variables**:
   ```bash
   # Extract IPs from Terraform output
   cd /home/ubuntu/terraform
   terraform output -json > /tmp/tf-output.json

   # Update 00.global_variable.sh with actual values
   vim /home/ubuntu/scripts/00.global_variable.sh
   ```

2. **Configure SSH**:
   ```bash
   # Set up SSH config for easy access
   cat >> ~/.ssh/config << EOF
   Host master01
       HostName <MASTER01_PRIVATE_IP>
       User ubuntu
       StrictHostKeyChecking no

   Host worker01
       HostName <WORKER01_PRIVATE_IP>
       User ubuntu
       StrictHostKeyChecking no
   # Add more hosts...
   EOF
   ```

3. **Run post-installation fixes**:
   ```bash
   cd /home/ubuntu/scripts
   bash 10.post_install_fixes.sh
   ```

---

## Adaptation Notes

When adapting these scripts for a new cluster:

1. **Update IP addresses** in `00.global_variable.sh`
2. **Verify SSH connectivity** to all nodes
3. **Check domain names** match your deployment
4. **Validate paths** to certificates and manifests
5. **Test each script individually** before running the master script

---

## Reference: terraform-layered Fixed IP Configuration

```
Master LB VIP:  172.16.0.54
Worker LB VIP:  172.16.0.88

Master Nodes (Fixed IPs):
- master01: 172.16.0.101
- master02: 172.16.0.102
- master03: 172.16.0.103

Worker Nodes (Fixed IPs):
- worker01: 172.16.0.111
- worker02: 172.16.0.112
- worker03: 172.16.0.113

Domain: k-paas.io
K-PaaS Version: 1.7.0
Kubernetes Version: v1.33.5
```
