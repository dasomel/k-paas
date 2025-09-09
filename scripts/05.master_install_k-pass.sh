#!/usr/bin/env bash
echo "========== 03.install_k-pass START =========="
# Reference : https://github.com/K-PaaS/container-platform/blob/master/install-guide/standalone/cp-cluster-install-single.md

# Global Variable Setting
source /vagrant/scripts/00.global_variable.sh

# v1.6.2 Release
echo "============== v1.6.2 source download =============="
wget -O v1.6.2.tar.gz https://github.com/K-PaaS/cp-deployment/archive/refs/tags/v1.6.2.tar.gz && tar -xzf v1.6.2.tar.gz && mv cp-deployment-1.6.2 cp-deployment

cp /vagrant/scripts/variable/cp-cluster-vars.sh "$INSTALL_PATH"/cp-deployment/single/cp-cluster-vars.sh

# ERROR: Failed to update apt cache: W:Updating from such a repository can't be done securely, and is therefore disabled by default.
sed -i '1,$c\
---\
- name: Install required packages\
  become: true\
  apt:\
    name:\
      - curl\
      - gpg\
      - apt-transport-https\
    state: present\
    update_cache: yes\
- name: Add Helm apt key (keyring)\
  become: true\
  shell: curl -fsSL https://packages.buildkite.com/helm-linux/helm-debian/gpgkey | gpg --dearmor | tee /usr/share/keyrings/helm.gpg > /dev/null\
- name: Add Helm apt repo (Buildkite-hosted)\
  become: true\
  shell: echo "deb [signed-by=/usr/share/keyrings/helm.gpg] https://packages.buildkite.com/helm-linux/helm-debian/any/ any main" | tee /etc/apt/sources.list.d/helm-stable-debian.list\
- name: Install Helm\
  become: true\
  apt:\
    name: helm\
    update_cache: yes
' "$INSTALL_PATH"/cp-deployment/single/roles/helm/tasks/main.yml

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
sed -i 's/nf_conntrack_ipv4/nf_conntrack/g' "$INSTALL_PATH"/cp-deployment/standalone/roles/kubernetes/node/tasks/main.yml
sed -i 's/nf_conntrack_ipv4/nf_conntrack/g' "$INSTALL_PATH"/cp-deployment/standalone/extra_playbooks/roles/kubernetes/node/tasks/main.yml

# ERROR: Stop if even number of etcd hosts: length is not divisibleby 2
sed -i 's/--become --become-user=root cluster.yml/--become --become-user=root cluster.yml -e ignore_assert_errors=yes/g' "$INSTALL_PATH"/cp-deployment/single/deploy-cp-cluster.sh

# ERROR: skipping: no hosts matched
sed -i 's/hosts.yaml/inventory.ini/g'                                                                                   "$INSTALL_PATH"/cp-deployment/standalone/deploy-cp-cluster.sh
sed -i'' -r -e "/# Deploy Container Platform/a\mv inventory/mycluster/inventory.ini inventory/mycluster/inventory.yml"  "$INSTALL_PATH"/cp-deployment/standalone/deploy-cp-cluster.sh
sed -i 's/inventory.ini  --become --become-user=root cluster.yml/inventory.yml  --become --become-user=root cluster.yml -e ignore_assert_errors=yes/g' "$INSTALL_PATH"/cp-deployment/standalone/deploy-cp-cluster.sh

# ERROR: The task includes an option with an undefined variable
sed -i.bak "s@{{ download.dest | basename }}@{% if download.dest is defined %}{{ download.dest | basename }}{% else %}{% endif %}@g" "$INSTALL_PATH"/cp-deployment/standalone/roles/download/tasks/download_file.yml
sed "s@{{ download.dest | basename }}@{% if download.dest is defined %}{{ download.dest | basename }}{% else %}{% endif %}@g" "$INSTALL_PATH"/cp-deployment/standalone/roles/download/tasks/download_file.yml

# ERROR: The conditional check '(modprobe_conntrack_module|default({'rc': 1})).rc != 0' failed. The error was: error while evaluating conditional ((modprobe_conntrack_module|default({'rc': 1})).rc != 0): 'dict object' has no attribute 'rc'. 'dict object' has no attribute 'rc'
sed -i '/- "(modprobe_conntrack_module|default({.rc.: 1})).rc != 0"/c\    - "(modprobe_conntrack_module is defined and modprobe_conntrack_module.results is defined and (modprobe_conntrack_module.results | selectattr('\''rc'\'', '\''defined'\'') | selectattr('\''rc'\'', '\''!=\'\'', 0) | list | length == (conntrack_modules | length)))"
' "$INSTALL_PATH"/cp-deployment/standalone/roles/kubernetes/node/tasks/main.yml

# ERROR: tee: /dev/tty: No such device or address
sed -i 's/tee \/dev\/tty/tee \~\/cp-deployment\/single\/deploy-result.log/g'                                            "$INSTALL_PATH"/cp-deployment/single/roles/cp-install/tasks/main.yml

# ARM64 Architecture Support
if [ "$(uname -m)" = "aarch64" ]; then
    echo "ARM64 Architecture Support"
    cp /vagrant/scripts/arm/security-arm.bin "$INSTALL_PATH"/cp-deployment/security.bin
    sed -i 's/amd64/arm64/g' "$INSTALL_PATH"/cp-deployment/single/roles/kubectl/tasks/main.yml
    sed -i 's/amd64/arm64/g' "$INSTALL_PATH"/cp-deployment/standalone/roles/kubespray_defaults/defaults/main/download.yml
fi

echo "========== deploy-cp-cluster START =========="

cd "$INSTALL_PATH"/cp-deployment/single || exit
source deploy-cp-cluster.sh
