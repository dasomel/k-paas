#!/bin/bash
# Harbor Certificate Configuration Script
# This script configures Harbor's self-signed certificate on all worker nodes
# for proper image pulling from the private registry

set -e

source /home/ubuntu/scripts/00.global_variable.sh

echo "========== Harbor Certificate Configuration =========="
echo "Worker LB Public IP: ${WORKER_LB_PUBLIC_IP}"
echo "Harbor Domain: harbor.k-paas.io"

# Step 1: Download Harbor certificate from master-1
echo ""
echo "Step 1: Downloading Harbor certificate from master-1..."
ssh -o StrictHostKeyChecking=no ubuntu@master01 << 'EOF'
echo | openssl s_client -showcerts -connect harbor.k-paas.io:443 2>/dev/null |     sed -n '/BEGIN CERTIFICATE/,/END CERTIFICATE/p' > /tmp/harbor-ca.crt
EOF

scp -o StrictHostKeyChecking=no ubuntu@master01:/tmp/harbor-ca.crt /tmp/harbor-ca.crt
echo "Harbor certificate downloaded"

# Step 2: Distribute certificate to all worker nodes
echo ""
echo "Step 2: Distributing certificate to worker nodes..."
for i in $(seq 1 ${WORKER_COUNT}); do
    WORKER_HOST="worker0${i}"
    echo "Configuring ${WORKER_HOST}..."

    # Copy certificate to worker
    scp -o StrictHostKeyChecking=no /tmp/harbor-ca.crt ubuntu@${WORKER_HOST}:/tmp/

    # Configure certificate on worker
    ssh -o StrictHostKeyChecking=no ubuntu@${WORKER_HOST} << 'WORKEREOF'
        # Add /etc/hosts entry
        if ! grep -q "harbor.k-paas.io" /etc/hosts; then
            echo " harbor.k-paas.io keycloak.k-paas.io portal.k-paas.io k-paas.io openbao.k-paas.io chartmuseum.k-paas.io" | sudo tee -a /etc/hosts
        fi

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

        # Restart CRI-O
        sudo systemctl restart crio

        echo "Certificate configured on $(hostname)"
WORKEREOF

    echo "${WORKER_HOST} configuration complete"
done

echo ""
echo "Step 3: Verifying certificate configuration..."
for i in $(seq 1 ${WORKER_COUNT}); do
    WORKER_HOST="worker0${i}"
    echo -n "Checking ${WORKER_HOST}: "
    ssh -o StrictHostKeyChecking=no ubuntu@${WORKER_HOST} "test -f /etc/containers/certs.d/harbor.k-paas.io/ca.crt && echo 'OK' || echo 'FAILED'"
done

echo ""
echo "========== Harbor Certificate Configuration Complete =========="
echo "All worker nodes are now configured to pull images from harbor.k-paas.io"