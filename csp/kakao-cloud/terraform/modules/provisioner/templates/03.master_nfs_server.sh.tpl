#!/usr/bin/env bash
set -e
# Auto-generated from Terraform at deployment time
# Reference: https://github.com/K-PaaS/container-platform/blob/master/install-guide/nfs-server-install-guide.md

echo "========== NFS Server Installation START =========="

# NFS Server Install
sudo apt-get update
sudo apt-get install -y nfs-common nfs-kernel-server rpcbind
sudo mkdir -p /home/share/nfs
sudo chmod -R 777 /home/share/nfs

# Configure NFS exports with all nodes
sudo cat <<EOF | sudo tee /etc/exports
## NFS exports for K-PaaS cluster
## Format: [/shared_directory] [access_IP] [option]
/home/share/nfs ${master1_private_ip}(rw,no_root_squash,async)
/home/share/nfs ${master2_private_ip}(rw,no_root_squash,async)
/home/share/nfs ${master3_private_ip}(rw,no_root_squash,async)
/home/share/nfs ${worker1_private_ip}(rw,no_root_squash,async)
/home/share/nfs ${worker2_private_ip}(rw,no_root_squash,async)
/home/share/nfs ${worker3_private_ip}(rw,no_root_squash,async)
/home/share/nfs 172.16.0.0/16(rw,no_root_squash,async)
EOF

# Restart NFS services
sudo exportfs -ra
sudo systemctl enable rpcbind
sudo systemctl restart rpcbind
sudo systemctl enable nfs-kernel-server
sudo systemctl restart nfs-kernel-server

# Verify NFS exports
echo "========== NFS Exports Status =========="
sudo exportfs -v

echo "========== NFS Server Installation COMPLETED =========="
