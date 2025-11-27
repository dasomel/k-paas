#!/usr/bin/env bash
set -e
echo "========== 06.master_install_k-pass_portal START =========="
# https://github.com/K-PaaS/container-platform/blob/master/install-guide/portal/cp-portal-standalone-guide.md

# Global Variable Setting
SCRIPTS_DIR="/home/ubuntu/scripts"
source "$SCRIPTS_DIR/00.global_variable.sh"

# Install Path
INSTALL_PATH="/home/ubuntu"

# Create Deployment file download directory
mkdir -p "$INSTALL_PATH/workspace/container-platform"
cd "$INSTALL_PATH/workspace/container-platform" || exit

# Download v1.6.2 Deployment file and check file path
if [ ! -f "cp-portal-deployment-v1.6.2.tar.gz" ]; then
    echo "Downloading CP Portal deployment files..."
    wget --content-disposition https://nextcloud.k-paas.org/index.php/s/x7ccTRQYrBHsTD4/download
    tar -xvf cp-portal-deployment-v1.6.2.tar.gz
else
    echo "CP Portal deployment files already downloaded"
fi

# Define variables for Container Platform Portal
echo "Configuring CP Portal variables..."
echo "  PORTAL_MASTER_NODE_PUBLIC_IP: ${PORTAL_MASTER_NODE_PUBLIC_IP}"
echo "  PORTAL_HOST_DOMAIN: ${PORTAL_HOST_DOMAIN}"

sed -i "s/{k8s master node public ip}/${PORTAL_MASTER_NODE_PUBLIC_IP}/g" \
    "$INSTALL_PATH/workspace/container-platform/cp-portal-deployment/script/cp-portal-vars.sh"

sed -i "s/{host domain}/${PORTAL_HOST_DOMAIN}/g" \
    "$INSTALL_PATH/workspace/container-platform/cp-portal-deployment/script/cp-portal-vars.sh"

sed -i 's/HOST_CLUSTER_IAAS_TYPE=\"1\"/HOST_CLUSTER_IAAS_TYPE=\"2\"/g' \
    "$INSTALL_PATH/workspace/container-platform/cp-portal-deployment/script/cp-portal-vars.sh"

sed -i 's/{container platform portal provider type}/standalone/g' \
    "$INSTALL_PATH/workspace/container-platform/cp-portal-deployment/script/cp-portal-vars.sh"

sed -i 's/IMAGE_PULL_POLICY=\"Always\"/IMAGE_PULL_POLICY=\"IfNotPresent\"/g' \
    "$INSTALL_PATH/workspace/container-platform/cp-portal-deployment/script/cp-portal-vars.sh"

# ARM64 Architecture Support
if [ "$(uname -m)" = "aarch64" ]; then
    echo "ARM64 Architecture Support"

    echo "Change Harbor image to support ARM64"
    sed -i '/cp -r \.\.\/values_orig \.\.\/values/a\
    cp /home/ubuntu/scripts/arm/helm/harbor-27.0.3.tgz ~/workspace/container-platform/cp-portal-deployment/charts/harbor-1.17.1.tgz\
    cp /home/ubuntu/scripts/arm/helm/harbor.yaml ~/workspace/container-platform/cp-portal-deployment/values/harbor.yaml' \
        "$INSTALL_PATH/workspace/container-platform/cp-portal-deployment/script/deploy-cp-portal.sh"

    # keycloak image change(arm does not support java 21)
    echo "Change Keycloak image from version 25 to 24"
    echo -e '\nimage:\n  tag: 24.0.5-debian-12-r8' | tee -a \
        "$INSTALL_PATH/workspace/container-platform/cp-portal-deployment/values_orig/keycloak.yaml"

    echo "Change K-PaaS Portal image to support ARM64"
    if [ -d "/home/ubuntu/scripts/arm/cp-portal/images" ]; then
        cp -r /home/ubuntu/scripts/arm/cp-portal/images/ \
            /home/ubuntu/workspace/container-platform/cp-portal-deployment/
    fi

    echo "podman build to support ARM64"
    sed -i 's/sudo podman build/sudo podman build --arch=arm64/g' \
        "$INSTALL_PATH/workspace/container-platform/cp-portal-deployment/script/deploy-cp-portal.sh"
fi

# container(cri-o) mirror setting
echo "Configuring CRI-O registry mirrors..."
sudo tee /etc/containers/registries.conf > /dev/null <<'EOF'
unqualified-search-registries = ["docker.io"]

[[registry]]
prefix = "docker.io"
location = "docker.io"
search = true

[[registry.mirror]]
location = "mirror.gcr.io"
insecure = false

[[registry.mirror]]
location = "public.ecr.aws"
insecure = false

[[registry.mirror]]
location = "quay.io"
insecure = false

[[registry]]
prefix = "docker.io/bitnami"
location = "docker.io/bitnami"
search = false

[[registry.mirror]]
location = "mirror.gcr.io/bitnami"
insecure = false

# Uncomment below to use local registry such as Harbor if needed
# [[registry]]
# prefix = "harbor.k-paas.io"
# location = "harbor.k-paas.io"
# insecure = true
# search = false
EOF

sudo systemctl restart crio || true

# Execute the Container Platform Portal deployment script
echo "========== Deploying CP Portal =========="
cd "$INSTALL_PATH/workspace/container-platform/cp-portal-deployment/script" || exit
chmod +x deploy-cp-portal.sh
./deploy-cp-portal.sh > deploy-portal-result.log 2>&1

# Adding entries to Pod /etc/hosts with HostAliases
echo "Adding HostAliases to CP Portal deployments..."
kubectl patch deployment cp-portal-terraman-deployment -n cp-portal --type "merge" \
    -p '{"spec":{"template":{"spec":{"hostAliases":[{"ip":"'${PORTAL_HOST_IP}'","hostnames":["'${PORTAL_HOST_DOMAIN}'","vault.'${PORTAL_HOST_DOMAIN}'","harbor.'${PORTAL_HOST_DOMAIN}'","portal.'${PORTAL_HOST_DOMAIN}'","keycloak.'${PORTAL_HOST_DOMAIN}'"]},{"ip":"'${CLUSTER_ENDPOINT}'","hostnames":["'${PORTAL_MASTER_NODE_PUBLIC_IP}'"]}]}}}}'

kubectl patch deployment cp-portal-metric-api-deployment -n cp-portal --type "merge" \
    -p '{"spec":{"template":{"spec":{"hostAliases":[{"ip":"'${PORTAL_HOST_IP}'","hostnames":["'${PORTAL_HOST_DOMAIN}'","vault.'${PORTAL_HOST_DOMAIN}'","harbor.'${PORTAL_HOST_DOMAIN}'","portal.'${PORTAL_HOST_DOMAIN}'","keycloak.'${PORTAL_HOST_DOMAIN}'"]},{"ip":"'${CLUSTER_ENDPOINT}'","hostnames":["'${PORTAL_MASTER_NODE_PUBLIC_IP}'"]}]}}}}'

kubectl patch deployment cp-portal-common-api-deployment -n cp-portal --type "merge" \
    -p '{"spec":{"template":{"spec":{"hostAliases":[{"ip":"'${PORTAL_HOST_IP}'","hostnames":["'${PORTAL_HOST_DOMAIN}'","vault.'${PORTAL_HOST_DOMAIN}'","harbor.'${PORTAL_HOST_DOMAIN}'","portal.'${PORTAL_HOST_DOMAIN}'","keycloak.'${PORTAL_HOST_DOMAIN}'"]},{"ip":"'${CLUSTER_ENDPOINT}'","hostnames":["'${PORTAL_MASTER_NODE_PUBLIC_IP}'"]}]}}}}'

kubectl patch deployment cp-portal-api-deployment -n cp-portal --type "merge" \
    -p '{"spec":{"template":{"spec":{"hostAliases":[{"ip":"'${PORTAL_HOST_IP}'","hostnames":["'${PORTAL_HOST_DOMAIN}'","vault.'${PORTAL_HOST_DOMAIN}'","harbor.'${PORTAL_HOST_DOMAIN}'","portal.'${PORTAL_HOST_DOMAIN}'","keycloak.'${PORTAL_HOST_DOMAIN}'"]},{"ip":"'${CLUSTER_ENDPOINT}'","hostnames":["'${PORTAL_MASTER_NODE_PUBLIC_IP}'"]}]}}}}'

kubectl patch deployment cp-portal-ui-deployment -n cp-portal --type "merge" \
    -p '{"spec":{"template":{"spec":{"hostAliases":[{"ip":"'${PORTAL_HOST_IP}'","hostnames":["'${PORTAL_HOST_DOMAIN}'","vault.'${PORTAL_HOST_DOMAIN}'","harbor.'${PORTAL_HOST_DOMAIN}'","portal.'${PORTAL_HOST_DOMAIN}'","keycloak.'${PORTAL_HOST_DOMAIN}'"]},{"ip":"'${CLUSTER_ENDPOINT}'","hostnames":["'${PORTAL_MASTER_NODE_PUBLIC_IP}'"]}]}}}}'

kubectl patch deployment cp-keycloak -n keycloak --type "merge" \
    -p '{"spec":{"template":{"spec":{"hostAliases":[{"ip":"'${PORTAL_HOST_IP}'","hostnames":["'${PORTAL_HOST_DOMAIN}'","vault.'${PORTAL_HOST_DOMAIN}'","harbor.'${PORTAL_HOST_DOMAIN}'","portal.'${PORTAL_HOST_DOMAIN}'","keycloak.'${PORTAL_HOST_DOMAIN}'"]},{"ip":"'${CLUSTER_ENDPOINT}'","hostnames":["'${PORTAL_MASTER_NODE_PUBLIC_IP}'"]}]}}}}'

echo "========== 06.master_install_k-pass_portal COMPLETED =========="
echo ""
echo "Portal Access Information:"
echo "  Portal URL: https://${PORTAL_HOST_DOMAIN}"
echo "  Harbor URL: https://harbor.${PORTAL_HOST_DOMAIN}"
echo "  Keycloak URL: https://keycloak.${PORTAL_HOST_DOMAIN}"
echo ""
echo "Please make sure to add the following to your /etc/hosts:"
echo "  ${PORTAL_HOST_IP} ${PORTAL_HOST_DOMAIN} harbor.${PORTAL_HOST_DOMAIN} keycloak.${PORTAL_HOST_DOMAIN} portal.${PORTAL_HOST_DOMAIN}"
echo ""
