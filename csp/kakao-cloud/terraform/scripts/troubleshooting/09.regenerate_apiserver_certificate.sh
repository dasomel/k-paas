#!/bin/bash

# API Server Certificate Regeneration Script
# This script regenerates API server certificates to include Master LB Public IP
# for external access to the Kubernetes API server

set -e

source /home/ubuntu/scripts?/00.global_variable.sh

echo "========== API Server Certificate Regeneration =========="
echo "Master LB Public IP: ${MASTER_LB_PUBLIC_IP}"
echo "Cluster Endpoint (NLB VIP): ${CLUSTER_ENDPOINT}"

# Function to regenerate certificate on a master node
regenerate_cert_on_master() {
    local MASTER_HOST=$1
    local LB_IP=$2
    local CLUSTER_VIP=$3

    echo ""
    echo "========== Processing ${MASTER_HOST} =========="

    # Create temporary script with all IPs injected
    cat > /tmp/regenerate_cert_${MASTER_HOST}.sh << REMOTEEF
#!/bin/bash
set -e

LB_IP="${LB_IP}"
CLUSTER_VIP="${CLUSTER_VIP}"

echo "Step 1: Backing up existing certificates..."
BACKUP_DIR="/etc/kubernetes/ssl_backup_\$(date +%Y%m%d_%H%M%S)"
sudo mkdir -p \${BACKUP_DIR}
sudo cp /etc/kubernetes/ssl/apiserver.crt \${BACKUP_DIR}/ 2>/dev/null || true
sudo cp /etc/kubernetes/ssl/apiserver.key \${BACKUP_DIR}/ 2>/dev/null || true
echo "Certificates backed up to \${BACKUP_DIR}"

echo "Step 2: Creating OpenSSL configuration..."
cat > /tmp/apiserver-san.cnf << CNFEOF
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
DNS.5 = localhost
DNS.6 = master01
DNS.7 = master02
DNS.8 = master03
DNS.9 = master02.cluster.local
DNS.10 = master03.cluster.local

# Master Nodes (Private IPs)
IP.1 = ${MASTER01}
IP.2 = ${MASTER02}
IP.3 = ${MASTER03}

# Worker Nodes (Private IPs)
IP.4 = ${WORKER01}
IP.5 = ${WORKER02}
IP.6 = ${WORKER03}

# Cluster IPs
IP.7 = 10.233.0.1
IP.8 = 127.0.0.1
IP.9 = ::1

# Cluster Endpoint (NLB VIP)
IP.10 = \${CLUSTER_VIP}

# External LB Public IP
IP.11 = \${LB_IP}
CNFEOF

echo "Generated SANs:"
grep "IP\." /tmp/apiserver-san.cnf

echo "Step 3: Creating Certificate Signing Request..."
sudo openssl req -new -key /etc/kubernetes/ssl/apiserver.key -out /tmp/apiserver.csr -subj "/CN=kube-apiserver" -config /tmp/apiserver-san.cnf

echo "Step 4: Signing certificate with CA..."
sudo openssl x509 -req -in /tmp/apiserver.csr -CA /etc/kubernetes/ssl/ca.crt -CAkey /etc/kubernetes/ssl/ca.key -CAcreateserial -out /tmp/apiserver-new.crt -days 3650 -extensions v3_req -extfile /tmp/apiserver-san.cnf

echo "Step 5: Replacing certificate..."
sudo mv /tmp/apiserver-new.crt /etc/kubernetes/ssl/apiserver.crt
sudo chmod 644 /etc/kubernetes/ssl/apiserver.crt
sudo chmod 600 /etc/kubernetes/ssl/apiserver.key

echo "Step 6: Restarting API server..."
API_SERVER_MANIFEST="/etc/kubernetes/manifests/kube-apiserver.yaml"
if [ -f "\${API_SERVER_MANIFEST}" ]; then
    sudo mv \${API_SERVER_MANIFEST} /tmp/kube-apiserver.yaml.tmp
    sleep 5
    sudo mv /tmp/kube-apiserver.yaml.tmp \${API_SERVER_MANIFEST}
    echo "API server manifest reloaded"
fi

echo "Waiting for API server to restart..."
sleep 15

echo "Step 7: Verifying new certificate SANs..."
sudo openssl x509 -in /etc/kubernetes/ssl/apiserver.crt -noout -text | grep -A 15 'Subject Alternative Name'

echo "Certificate regeneration complete on \$(hostname)"
rm -f /tmp/apiserver-san.cnf /tmp/apiserver.csr /tmp/apiserver-new.crt
REMOTEEF

    # Copy and execute on remote host
    scp -i /home/ubuntu/.ssh/kaas_keypriar.pem /tmp/regenerate_cert_${MASTER_HOST}.sh ubuntu@${MASTER_HOST}:/tmp/
    ssh -i /home/ubuntu/.ssh/kaas_keypriar.pem -o StrictHostKeyChecking=no ubuntu@${MASTER_HOST} \
        "chmod +x /tmp/regenerate_cert_${MASTER_HOST}.sh && /tmp/regenerate_cert_${MASTER_HOST}.sh"

    rm -f /tmp/regenerate_cert_${MASTER_HOST}.sh
}

# Step 1: Update Kubespray configuration
echo ""
echo "Step 1: Updating Kubespray configuration..."
sudo sed -i "s|# supplementary_addresses_in_ssl_keys:.*|supplementary_addresses_in_ssl_keys: [${MASTER_LB_PUBLIC_IP}]|" \
    /home/ubuntu/cp-deployment/standalone/inventory/mycluster/group_vars/k8s_cluster/k8s-cluster.yml 2>/dev/null || true

# Step 2: Regenerate certificates on all master nodes
echo ""
echo "Step 2: Regenerating certificates on all master nodes..."
for i in 1 2 3; do
    regenerate_cert_on_master "master0${i}" "${MASTER_LB_PUBLIC_IP}" "${CLUSTER_ENDPOINT}"
done

# Step 3: Verify all API servers are running
echo ""
echo "Step 3: Verifying API servers..."
sleep 10
kubectl get pod -n kube-system | grep kube-apiserver

# Step 4: Create external kubeconfig
echo ""
echo "Step 4: Creating external kubeconfig..."
kubectl config view --minify --raw > /tmp/kubeconfig-external.yaml
sed -i "s|https://.*:6443|https://${MASTER_LB_PUBLIC_IP}:6443|g" /tmp/kubeconfig-external.yaml

echo ""
echo "========== API Server Certificate Regeneration Complete =========="
echo "All master nodes now have certificates that include:"
echo "  - Master Nodes: ${MASTER01}, ${MASTER02}, ${MASTER03}"
echo "  - Worker Nodes: ${WORKER01}, ${WORKER02}, ${WORKER03}"
echo "  - NLB VIP: ${CLUSTER_ENDPOINT}"
echo "  - Public LB IP: ${MASTER_LB_PUBLIC_IP}"
echo "External kubeconfig saved to: /tmp/kubeconfig-external.yaml"
