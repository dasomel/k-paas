#!/usr/bin/env bash
echo "========== 03.install_k-pass START =========="
# Reference : https://github.com/K-PaaS/container-platform/blob/master/install-guide/standalone/cp-cluster-install-single.md

# Global Variable Setting
source /vagrant/scripts/00.global_variable.sh

# v1.5.1(2024.4.16) Release
echo "============== git clone START =============="
git clone https://github.com/K-PaaS/cp-deployment.git -b branch_v1.5.x

cp /vagrant/scripts/variable/cp-cluster-vars.sh "$INSTALL_PATH"/cp-deployment/single/cp-cluster-vars.sh

# ERROR: modprobe: FATAL: Module nf_conntrack_ipv4 not found in directory
sed -i 's/nf_conntrack_ipv4/nf_conntrack/g' "$INSTALL_PATH"/cp-deployment/standalone/roles/kubernetes/node/tasks/main.yml
sed -i 's/nf_conntrack_ipv4/nf_conntrack/g' "$INSTALL_PATH"/cp-deployment/standalone/extra_playbooks/roles/kubernetes/node/tasks/main.yml

# ERROR: Stop if even number of etcd hosts: length is not divisibleby 2
sed -i 's/--become --become-user=root cluster.yml/--become --become-user=root cluster.yml -e ignore_assert_errors=yes/g' "$INSTALL_PATH"/cp-deployment/single/deploy-cp-cluster.sh

# ERROR: skipping: no hosts matched
sed -i 's/hosts.yaml/inventory.ini/g'                                                                                   "$INSTALL_PATH"/cp-deployment/standalone/deploy-cp-cluster.sh
sed -i'' -r -e "/# Deploy Container Platform/a\mv inventory/mycluster/inventory.ini inventory/mycluster/inventory.yml"  "$INSTALL_PATH"/cp-deployment/standalone/deploy-cp-cluster.sh
sed -i 's/inventory.ini  --become --become-user=root cluster.yml/inventory.yml  --become --become-user=root cluster.yml -e ignore_assert_errors=yes/g' "$INSTALL_PATH"/cp-deployment/standalone/deploy-cp-cluster.sh

# kubectl version change(1.27.5 -> 1.28.6)
sed -i 's/v1.27.5/v1.28.6/g' "$INSTALL_PATH"/cp-deployment/single/roles/kubectl/tasks/main.yml

echo "========== deploy-cp-cluster START =========="

cd "$INSTALL_PATH"/cp-deployment/single || exit
source deploy-cp-cluster.sh
