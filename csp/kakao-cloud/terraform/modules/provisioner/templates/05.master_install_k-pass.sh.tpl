#!/usr/bin/env bash
set -e
echo "========== 05.master_install_k-pass START =========="

# Global Variable Setting
SCRIPTS_DIR="/home/ubuntu/scripts"
source "$SCRIPTS_DIR/00.global_variable.sh"

# Install Path
INSTALL_PATH="/home/ubuntu"
cd "$INSTALL_PATH" || exit 1

# --- Download and Extract Source Code ---
if [ ! -d "$INSTALL_PATH/cp-deployment" ]; then
  echo ">>> Downloading and extracting v1.7.0 source..."
  wget -O v1.7.0.tar.gz https://github.com/K-PaaS/cp-deployment/archive/refs/tags/v1.7.0.tar.gz && tar -xzf v1.7.0.tar.gz && mv cp-deployment-1.7.0 cp-deployment
else
  echo ">>> cp-deployment directory already exists. Skipping download."
fi

# --- Create Ansible Inventory File Directly ---
echo ">>> Generating Ansible inventory file..."
tee "$INSTALL_PATH"/cp-deployment/standalone/inventory/mycluster/inventory.ini > /dev/null <<EOF
[all]
${master01_hostname} ansible_host=${master01_ip} ip=${master01_ip} access_ip=${master01_ip} etcd_member_name=etcd1
${master02_hostname} ansible_host=${master02_ip} ip=${master02_ip} access_ip=${master02_ip} etcd_member_name=etcd2
${master03_hostname} ansible_host=${master03_ip} ip=${master03_ip} access_ip=${master03_ip} etcd_member_name=etcd3
${worker01_hostname} ansible_host=${worker01_ip} ip=${worker01_ip} access_ip=${worker01_ip}
${worker02_hostname} ansible_host=${worker02_ip} ip=${worker02_ip} access_ip=${worker02_ip}
${worker03_hostname} ansible_host=${worker03_ip} ip=${worker03_ip} access_ip=${worker03_ip}

[kube_control_plane]
${master01_hostname}
${master02_hostname}
${master03_hostname}

[etcd]
${master01_hostname}
${master02_hostname}
${master03_hostname}

[kube_node]
${worker01_hostname}
${worker02_hostname}
${worker03_hostname}

[calico_rr]

[k8s_cluster:children]
kube_control_plane
kube_node
calico_rr
EOF

echo ">>> Generated inventory.ini content:"
cat "$INSTALL_PATH"/cp-deployment/standalone/inventory/mycluster/inventory.ini

# --- Create cri-o group_vars ---
echo ">>> Creating cri-o group_vars..."
mkdir -p "$INSTALL_PATH"/cp-deployment/standalone/inventory/mycluster/group_vars/all
tee "$INSTALL_PATH"/cp-deployment/standalone/inventory/mycluster/group_vars/all/cri-o.yml > /dev/null <<'EOF'
unqualified_search_registries:
  - docker.io
registries:
  - prefix: "docker.io"
    location: "docker.io"
    mirrors:
      - location: "mirror.gcr.io"
        insecure: false
      - location: "public.ecr.aws"
        insecure: false
      - location: "quay.io"
        insecure: false
  - prefix: "docker.io/bitnami"
    location: "docker.io/bitnami"
    mirrors:
      - location: "mirror.gcr.io/bitnami"
        insecure: false
search_registries:
  - docker.io
  - quay.io
EOF

# --- Apply Necessary Patches ---
echo ">>> Applying patches..."
if [ -f "$INSTALL_PATH"/cp-deployment/standalone/roles/kubernetes/node/tasks/main.yml ]; then
  sed -i 's/nf_conntrack_ipv4/nf_conntrack/g' "$INSTALL_PATH"/cp-deployment/standalone/roles/kubernetes/node/tasks/main.yml
fi
if [ -f "$INSTALL_PATH"/cp-deployment/standalone/extra_playbooks/roles/kubernetes/node/tasks/main.yml ]; then
  sed -i 's/nf_conntrack_ipv4/nf_conntrack/g' "$INSTALL_PATH"/cp-deployment/standalone/extra_playbooks/roles/kubernetes/node/tasks/main.yml
fi

# Remove bastion from inventory template (causes SSH connection issues in single mode)
echo ">>> Removing bastion from inventory template..."
if [ -f "$INSTALL_PATH"/cp-deployment/standalone/roles/cp/local/pre-set/templates/inventory.ini.j2 ]; then
  sed -i '/^\[bastion\]/,/^$/d' "$INSTALL_PATH"/cp-deployment/standalone/roles/cp/local/pre-set/templates/inventory.ini.j2
fi

# Disable bastion-related tasks in cp-download role (no bastion in cloud environment)
echo ">>> Disabling bastion-related tasks in cp-download role..."
if [ -f "$INSTALL_PATH"/cp-deployment/standalone/roles/cp/cluster/cp-download/tasks/main.yml ]; then
  # Add when condition to skip bastion tasks
  sed -i '/- name: Fetch cp-deployment archive from controller to bastion/,/delegate_to: "bastion"/s/^/# DISABLED: /' "$INSTALL_PATH"/cp-deployment/standalone/roles/cp/cluster/cp-download/tasks/main.yml
  sed -i '/- name: Extract cp-deployment on bastion/,/remote_src: true/s/^/# DISABLED: /' "$INSTALL_PATH"/cp-deployment/standalone/roles/cp/cluster/cp-download/tasks/main.yml
  sed -i '/- name: Cleanup tar file on bastion/,/state: absent/s/^/# DISABLED: /' "$INSTALL_PATH"/cp-deployment/standalone/roles/cp/cluster/cp-download/tasks/main.yml
fi

# --- Configure cp-cluster-vars.sh ---
echo ">>> Configuring cp-cluster-vars.sh..."
tee "$INSTALL_PATH"/cp-deployment/single/cp-cluster-vars.sh > /dev/null <<EOF
#!/bin/bash

# Control Plane 노드 설정 (3 Masters)
KUBE_CONTROL_HOSTS=3

# Control Plane (Master) 노드 정보
MASTER1_NODE_HOSTNAME=${master01_hostname}
MASTER1_NODE_USER=ubuntu
MASTER1_NODE_PRIVATE_IP=${master01_ip}
MASTER1_NODE_PUBLIC_IP=${master01_ip}
MASTER2_NODE_HOSTNAME=${master02_hostname}
MASTER2_NODE_PRIVATE_IP=${master02_ip}
MASTER3_NODE_HOSTNAME=${master03_hostname}
MASTER3_NODE_PRIVATE_IP=${master03_ip}

# LoadBalancer 설정
LOADBALANCER_DOMAIN=${cluster_endpoint}

# ETCD 노드 설정 (stacked: etcd runs on master nodes)
ETCD_TYPE=stacked

ETCD1_NODE_HOSTNAME=
ETCD1_NODE_PRIVATE_IP=
ETCD2_NODE_HOSTNAME=
ETCD2_NODE_PRIVATE_IP=
ETCD3_NODE_HOSTNAME=
ETCD3_NODE_PRIVATE_IP=

# Worker 노드 설정 (3 Workers)
KUBE_WORKER_HOSTS=3

WORKER1_NODE_HOSTNAME=${worker01_hostname}
WORKER1_NODE_PRIVATE_IP=${worker01_ip}
WORKER2_NODE_HOSTNAME=${worker02_hostname}
WORKER2_NODE_PRIVATE_IP=${worker02_ip}
WORKER3_NODE_HOSTNAME=${worker03_hostname}
WORKER3_NODE_PRIVATE_IP=${worker03_ip}

# Storage 설정
STORAGE_TYPE=nfs
NFS_SERVER_PRIVATE_IP=${master01_ip}

# MetalLB 설정
METALLB_IP_RANGE=${metallb_ip_range}
INGRESS_NGINX_IP=${ingress_nginx_ip}

# Kyverno 설정
INSTALL_KYVERNO=Y

# CSP LoadBalancer Controller 설정
CSP_TYPE=

NHN_USERNAME=
NHN_PASSWORD=
NHN_TENANT_ID=
NHN_VIP_SUBNET_ID=
NHN_API_BASE_URL=https://kr1-api-network-infrastructure.nhncloudservice.com

NAVER_CLOUD_API_KEY=
NAVER_CLOUD_API_SECRET=
NAVER_CLOUD_REGION=KR
NAVER_CLOUD_VPC_NO=
NAVER_CLOUD_SUBNET_NO=
EOF

# --- Patch deploy-cp-cluster.sh to wait for ingress-nginx before running single.yml ---
echo ">>> Patching deploy-cp-cluster.sh to wait for ingress-nginx..."
if [ -f "$INSTALL_PATH"/cp-deployment/single/deploy-cp-cluster.sh ]; then
    # Add wait logic before single.yml playbook execution
    sed -i '/ansible-playbook.*single\.yml/i\
# Wait for ingress-nginx namespace and controller to be ready\
echo "Waiting for ingress-nginx to be ready..."\
for i in {1..60}; do\
    if kubectl get namespace ingress-nginx >/dev/null 2>&1 && \\\
       kubectl get svc ingress-nginx-controller -n ingress-nginx >/dev/null 2>&1; then\
        echo "ingress-nginx is ready"\
        sleep 10  # Additional wait for service to stabilize\
        break\
    fi\
    echo "Waiting for ingress-nginx... ($i/60)"\
    sleep 10\
done
' "$INSTALL_PATH"/cp-deployment/single/deploy-cp-cluster.sh
fi

# --- Run Deployment ---
echo ">>> Starting deployment..."
cd "$INSTALL_PATH"/cp-deployment/single || exit
./deploy-cp-cluster.sh

# --- Setup kubectl configuration for ubuntu user ---
echo ">>> Setting up kubectl configuration..."
mkdir -p ~/.kube
sudo cp /etc/kubernetes/admin.conf ~/.kube/config
sudo chown ubuntu:ubuntu ~/.kube/config
echo ">>> kubectl configuration completed"

# --- Approve kubelet serving certificates ---
echo ">>> Approving kubelet serving certificates..."
# Wait for CSRs to be created
sleep 5
# Approve all pending kubelet-serving CSRs
kubectl get csr -o name | grep kubelet-serving | while read -r csr; do
  kubectl certificate approve "$csr" 2>/dev/null || true
done
echo ">>> Kubelet serving certificates approved"

# --- Install NFS Provisioner for StorageClass ---
echo ">>> Installing NFS provisioner..."
cd "$INSTALL_PATH"/cp-deployment/applications/nfs-subdir-external-provisioner-4.0.18 || exit
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner 2>/dev/null || true
helm repo update
helm upgrade --install nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner -f values.yaml --version 4.0.18

echo ">>> Waiting for NFS provisioner to be ready..."
kubectl wait --for=condition=ready pod -l app=nfs-subdir-external-provisioner --timeout=300s || true

echo ">>> NFS provisioner installed"
kubectl get storageclass

# --- Install ingress-nginx controller ---
echo ">>> Installing ingress-nginx controller..."
kubectl apply -f "$INSTALL_PATH"/cp-deployment/applications/ingress-nginx-1.13.3/deploy.yaml

echo ">>> Waiting for ingress-nginx controller to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/component=controller -n ingress-nginx --timeout=300s || true

# Patch ingress-nginx with loadBalancerIP
echo ">>> Patching ingress-nginx with loadBalancerIP..."
kubectl patch svc ingress-nginx-controller -p '{"spec":{"loadBalancerIP":"${ingress_nginx_ip}"}}' -n ingress-nginx

echo ">>> ingress-nginx controller installed"
kubectl get svc -n ingress-nginx

# --- Verify cluster is ready ---
echo ">>> Verifying cluster status..."
kubectl get nodes
kubectl get pods -n kube-system
kubectl get svc -n ingress-nginx

echo "========== 05.master_install_k-pass COMPLETED =========="
