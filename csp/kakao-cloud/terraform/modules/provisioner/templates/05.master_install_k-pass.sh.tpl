#!/usr/bin/env bash
set -e
echo "========== 05.master_install_k-pass START =========="
# Reference : https://github.com/K-PaaS/container-platform/blob/master/install-guide/standalone/cp-cluster-install-single.md

# Global Variable Setting
SCRIPTS_DIR="/home/ubuntu/scripts"
source "$SCRIPTS_DIR/00.global_variable.sh"

# Install Path
INSTALL_PATH="/home/ubuntu"
cd "$INSTALL_PATH" || exit 1

# v1.6.2 Release
echo "============== v1.6.2 source download =============="
if [ ! -d "$INSTALL_PATH/cp-deployment" ]; then
    wget -O v1.6.2.tar.gz https://github.com/K-PaaS/cp-deployment/archive/refs/tags/v1.6.2.tar.gz
    tar -xzf v1.6.2.tar.gz
    mv cp-deployment-1.6.2 cp-deployment
else
    echo "cp-deployment directory already exists, skipping download"
fi

# Copy cp-cluster-vars.sh from scripts/variable to standalone directory
cp "$SCRIPTS_DIR/variable/cp-cluster-vars.sh" "$INSTALL_PATH/cp-deployment/standalone/cp-cluster-vars.sh"

# container(cri-o) mirror setting
tee ~/cp-deployment/standalone/inventory/mycluster/group_vars/all/cri-o.yml > /dev/null <<'EOF'
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

# If needed, add: local registries such as Harbor
#  - prefix: "harbor.k-paas.io"
#    location: "harbor.k-paas.io"
#    insecure: true

search_registries:
  - docker.io
  - quay.io
#  - harbor.k-paas.io  # Uncomment if needed.
EOF

# ERROR: modprobe: FATAL: Module nf_conntrack_ipv4 not found in directory
sed -i 's/nf_conntrack_ipv4/nf_conntrack/g' "$INSTALL_PATH/cp-deployment/standalone/roles/kubernetes/node/tasks/main.yml"
sed -i 's/nf_conntrack_ipv4/nf_conntrack/g' "$INSTALL_PATH/cp-deployment/standalone/extra_playbooks/roles/kubernetes/node/tasks/main.yml"

# ERROR: Stop if even number of etcd hosts (not needed for standalone - 3 masters is OK)

# ERROR: skipping: no hosts matched
sed -i 's/hosts.yaml/inventory.ini/g' "$INSTALL_PATH/cp-deployment/standalone/deploy-cp-cluster.sh"
sed -i'' -r -e "/# Deploy Container Platform/a\mv inventory/mycluster/inventory.ini inventory/mycluster/inventory.yml" "$INSTALL_PATH/cp-deployment/standalone/deploy-cp-cluster.sh"
sed -i 's/inventory.ini  --become --become-user=root cluster.yml/inventory.yml  --become --become-user=root cluster.yml -e ignore_assert_errors=yes/g' "$INSTALL_PATH/cp-deployment/standalone/deploy-cp-cluster.sh"

# ERROR: The task includes an option with an undefined variable
sed -i.bak "s@{{ download.dest | basename }}@{% if download.dest is defined %}{{ download.dest | basename }}{% else %}{% endif %}@g" "$INSTALL_PATH/cp-deployment/standalone/roles/download/tasks/download_file.yml"

# ERROR: modprobe_conntrack_module error
sed -i '/- "(modprobe_conntrack_module|default({.rc.: 1})).rc != 0"/c\    - "(modprobe_conntrack_module is defined and modprobe_conntrack_module.results is defined and (modprobe_conntrack_module.results | selectattr('\''rc'\'', '\''defined'\'') | selectattr('\''rc'\'', '\''!=\'\'', 0) | list | length == (conntrack_modules | length)))"
' "$INSTALL_PATH/cp-deployment/standalone/roles/kubernetes/node/tasks/main.yml"

# ERROR: tee: /dev/tty: No such device or address (not applicable for standalone)

# ARM64 Architecture Support
if [ "$(uname -m)" = "aarch64" ]; then
    echo "ARM64 Architecture Support"
    cp "$SCRIPTS_DIR/arm/security-arm.bin" "$INSTALL_PATH/cp-deployment/security.bin"
    sed -i 's/amd64/arm64/g' "$INSTALL_PATH/cp-deployment/standalone/roles/kubespray_defaults/defaults/main/download.yml"
fi

echo "========== deploy-cp-cluster START =========="
cd "$INSTALL_PATH/cp-deployment/standalone" || exit

# Run deployment
source deploy-cp-cluster.sh

echo "========== deploy-cp-cluster COMPLETED =========="
