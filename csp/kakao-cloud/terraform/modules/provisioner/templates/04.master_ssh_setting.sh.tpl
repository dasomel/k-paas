#!/usr/bin/env bash
set -e
# Auto-generated from Terraform at deployment time

echo "========== SSH Key Distribution START =========="

# Load global variables
source /home/ubuntu/scripts/00.global_variable.sh

# Install sshpass
sudo apt-get update
sudo apt-get install -y sshpass

# Generate SSH key if not exists
if [ ! -f ~/.ssh/id_rsa ]; then
    ssh-keygen -t rsa-sha2-512 -b 4096 -N '' -f ~/.ssh/id_rsa <<< y
fi

# Remove old host keys
ssh-keygen -R ${master1_private_ip} 2>/dev/null || true
ssh-keygen -R ${master2_private_ip} 2>/dev/null || true
ssh-keygen -R ${master3_private_ip} 2>/dev/null || true
ssh-keygen -R ${worker1_private_ip} 2>/dev/null || true
ssh-keygen -R ${worker2_private_ip} 2>/dev/null || true
ssh-keygen -R ${worker3_private_ip} 2>/dev/null || true

# Scan and add host keys
echo "Scanning host keys..."
ssh-keyscan -H ${master1_private_ip} >> ~/.ssh/known_hosts 2>/dev/null
ssh-keyscan -H ${master2_private_ip} >> ~/.ssh/known_hosts 2>/dev/null
ssh-keyscan -H ${master3_private_ip} >> ~/.ssh/known_hosts 2>/dev/null
ssh-keyscan -H ${worker1_private_ip} >> ~/.ssh/known_hosts 2>/dev/null
ssh-keyscan -H ${worker2_private_ip} >> ~/.ssh/known_hosts 2>/dev/null
ssh-keyscan -H ${worker3_private_ip} >> ~/.ssh/known_hosts 2>/dev/null

# SSH config for no strict host checking (for automation)
cat << EOF | tee -a ~/.ssh/config
Host *
    StrictHostKeyChecking no
    UserKnownHostsFile=/dev/null
EOF

chmod 600 ~/.ssh/config

# Copy SSH public key to all nodes
# Note: This assumes SSH password is set or key-based auth is already configured
echo "Distributing SSH keys to all nodes..."

# You may need to manually copy keys or use cloud-init for initial access
# For now, we'll skip automated password-based copy
echo "NOTE: SSH key distribution requires initial access to all nodes"
echo "You may need to manually copy keys using:"
echo "  ssh-copy-id ubuntu@${master1_private_ip}"
echo "  ssh-copy-id ubuntu@${master2_private_ip}"
echo "  ssh-copy-id ubuntu@${master3_private_ip}"
echo "  ssh-copy-id ubuntu@${worker1_private_ip}"
echo "  ssh-copy-id ubuntu@${worker2_private_ip}"
echo "  ssh-copy-id ubuntu@${worker3_private_ip}"

echo "========== SSH Key Distribution COMPLETED =========="
