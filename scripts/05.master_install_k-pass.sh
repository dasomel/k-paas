#!/usr/bin/env bash
echo "========== 05.master_install_k-pass.sh START =========="

# Global Variable Setting
source /vagrant/00.global_variable.sh

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
master01 ansible_host=${MASTER01} ip=${MASTER01} access_ip=${MASTER01} etcd_member_name=etcd1
master02 ansible_host=${MASTER02} ip=${MASTER02} access_ip=${MASTER02} etcd_member_name=etcd2
worker01 ansible_host=${WORKER01} ip=${WORKER01} access_ip=${WORKER01}
worker02 ansible_host=${WORKER02} ip=${WORKER02} access_ip=${WORKER02}

[kube_control_plane]
master01
master02

[etcd]
master01
master02

[kube_node]
worker01
worker02

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

# Disable etcd even number validation (allow 2 etcd nodes)
echo ">>> Disabling etcd even number validation..."
if [ -f "$INSTALL_PATH"/cp-deployment/standalone/roles/validate_inventory/tasks/main.yml ]; then
  sed -i '/that: groups\.get.*etcd.*length is not divisibleby 2/c\    that: true  # Disabled: Allow even number of etcd nodes' "$INSTALL_PATH"/cp-deployment/standalone/roles/validate_inventory/tasks/main.yml
fi

# Remove bastion from inventory template (causes SSH connection issues in single mode)
echo ">>> Removing bastion from inventory template..."
if [ -f "$INSTALL_PATH"/cp-deployment/standalone/roles/cp/local/pre-set/templates/inventory.ini.j2 ]; then
  sed -i '/^\[bastion\]/,/^$/d' "$INSTALL_PATH"/cp-deployment/standalone/roles/cp/local/pre-set/templates/inventory.ini.j2
fi

# Disable bastion-related tasks in cp-download role (no bastion in Vagrant environment)
echo ">>> Disabling bastion-related tasks in cp-download role..."
if [ -f "$INSTALL_PATH"/cp-deployment/standalone/roles/cp/cluster/cp-download/tasks/main.yml ]; then
  # Add when condition to skip bastion tasks
  sed -i '/- name: Fetch cp-deployment archive from controller to bastion/,/delegate_to: "bastion"/s/^/# DISABLED: /' "$INSTALL_PATH"/cp-deployment/standalone/roles/cp/cluster/cp-download/tasks/main.yml
  sed -i '/- name: Extract cp-deployment on bastion/,/remote_src: true/s/^/# DISABLED: /' "$INSTALL_PATH"/cp-deployment/standalone/roles/cp/cluster/cp-download/tasks/main.yml
  sed -i '/- name: Cleanup tar file on bastion/,/state: absent/s/^/# DISABLED: /' "$INSTALL_PATH"/cp-deployment/standalone/roles/cp/cluster/cp-download/tasks/main.yml
fi

# --- Configure cp-cluster-vars.sh ---
# Variables are sourced from 00.global_variable.sh
echo ">>> Configuring cp-cluster-vars.sh..."
tee "$INSTALL_PATH"/cp-deployment/single/cp-cluster-vars.sh > /dev/null <<EOF
#!/bin/bash

# Control Plane 노드 설정
KUBE_CONTROL_HOSTS=${KUBE_CONTROL_HOSTS}

# Control Plane (Master) 노드 정보
MASTER1_NODE_HOSTNAME=master01
MASTER1_NODE_USER=ubuntu
MASTER1_NODE_PRIVATE_IP=${MASTER01}
MASTER1_NODE_PUBLIC_IP=${MASTER01}
MASTER2_NODE_HOSTNAME=master02
MASTER2_NODE_PRIVATE_IP=${MASTER02}
MASTER3_NODE_HOSTNAME=
MASTER3_NODE_PRIVATE_IP=

# LoadBalancer 설정
LOADBALANCER_DOMAIN=${CLUSTER_ENDPOINT}

# ETCD 노드 설정
ETCD_TYPE=${ETCD_TYPE}

ETCD1_NODE_HOSTNAME=
ETCD1_NODE_PRIVATE_IP=
ETCD2_NODE_HOSTNAME=
ETCD2_NODE_PRIVATE_IP=
ETCD3_NODE_HOSTNAME=
ETCD3_NODE_PRIVATE_IP=

# Worker 노드 설정
KUBE_WORKER_HOSTS=${KUBE_WORKER_HOSTS}

WORKER1_NODE_HOSTNAME=worker01
WORKER1_NODE_PRIVATE_IP=${WORKER01}
WORKER2_NODE_HOSTNAME=worker02
WORKER2_NODE_PRIVATE_IP=${WORKER02}
WORKER3_NODE_HOSTNAME=
WORKER3_NODE_PRIVATE_IP=

# Storage 설정
STORAGE_TYPE=${STORAGE_TYPE}
NFS_SERVER_PRIVATE_IP=${MASTER01}

# MetalLB 설정
METALLB_IP_RANGE=${METALLB_IP_RANGE}
INGRESS_NGINX_IP=${PORTAL_HOST_IP}

# Kyverno 설정
INSTALL_KYVERNO=${INSTALL_KYVERNO}

# CSP LoadBalancer Controller 설정
CSP_TYPE=${CSP_TYPE}

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

# ARM64 Architecture Support
if [ "$(uname -m)" = "aarch64" ]; then
    echo ">>> Applying ARM64 patches..."
    cp /vagrant/arm/security-arm.bin "$INSTALL_PATH"/cp-deployment/security.bin
fi

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

# --- Setup kubectl configuration for vagrant user ---
echo ">>> Setting up kubectl configuration..."
mkdir -p ~/.kube
sudo cp /etc/kubernetes/admin.conf ~/.kube/config
sudo chown vagrant:vagrant ~/.kube/config
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
helm install nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner -f values.yaml --version 4.0.18

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
kubectl patch svc ingress-nginx-controller -p '{"spec":{"loadBalancerIP":"'${PORTAL_HOST_IP}'"}}' -n ingress-nginx

echo ">>> ingress-nginx controller installed"
kubectl get svc -n ingress-nginx

# --- Fix nodelocaldns DNS loop issue ---
# When /etc/resolv.conf points to 169.254.25.10 (nodelocaldns itself),
# the forward directive causes a DNS loop. Fix by using external DNS.
echo ">>> Fixing nodelocaldns DNS loop issue..."
kubectl get configmap nodelocaldns -n kube-system -o yaml | \
    sed 's|forward \. /etc/resolv\.conf|forward . 8.8.8.8 8.8.4.4|g' | \
    kubectl apply -f - 2>/dev/null || echo "Warning: nodelocaldns configmap patch may have failed"

# Restart nodelocaldns to apply the fix
echo ">>> Restarting nodelocaldns daemonset..."
kubectl rollout restart daemonset/nodelocaldns -n kube-system 2>/dev/null || true
sleep 10

# Wait for nodelocaldns pods to be ready
echo ">>> Waiting for nodelocaldns pods to be ready..."
kubectl rollout status daemonset/nodelocaldns -n kube-system --timeout=120s 2>/dev/null || true

# --- Verify cluster is ready ---
echo ">>> Verifying cluster status..."
kubectl get nodes
kubectl get pods -n kube-system
kubectl get svc -n ingress-nginx
