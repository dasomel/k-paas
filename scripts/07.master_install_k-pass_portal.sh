#!/usr/bin/env bash
echo "========== 04.install_k-pass Portal START =========="
# https://github.com/K-PaaS/container-platform/blob/master/install-guide/portal/cp-portal-standalone-guide.md

# Global Variable Setting
source /vagrant/scripts/00.global_variable.sh

# Deployment 파일 다운로드 경로 생성
mkdir -p "$INSTALL_PATH"/workspace/container-platform
cd "$INSTALL_PATH"/workspace/container-platform || exit

# Deployment 파일 다운로드 및 파일 경로 확인
wget --content-disposition https://nextcloud.k-paas.org/index.php/s/2Sy2jzoJRx4aToM/download

# Deployment 파일 압축 해제
tar -xvf cp-portal-deployment-v1.5.1.tar.gz

# 컨테이너 플랫폼 포털 변수 정의
sed -i 's/{k8s master node public ip}/${PORTAL_MASTER_NODE_PUBLIC_IP}/g'      "$INSTALL_PATH"/workspace/container-platform/cp-portal-deployment/script/cp-portal-vars.sh
sed -i 's/{host domain}/${PORTAL_HOST_DOMAIN}/g'                              "$INSTALL_PATH"/workspace/container-platform/cp-portal-deployment/script/cp-portal-vars.sh
sed -i 's/HOST_CLUSTER_IAAS_TYPE=\"1\"/HOST_CLUSTER_IAAS_TYPE=\"2\"/g'        "$INSTALL_PATH"/workspace/container-platform/cp-portal-deployment/script/cp-portal-vars.sh
sed -i 's/{container platform portal provider type}/standalone/g'             "$INSTALL_PATH"/workspace/container-platform/cp-portal-deployment/script/cp-portal-vars.sh
sed -i 's/IMAGE_PULL_POLICY=\"Always\"/IMAGE_PULL_POLICY=\"IfNotPresent\"/g'  "$INSTALL_PATH"/workspace/container-platform/cp-portal-deployment/script/cp-portal-vars.sh

# 컨테이너 플랫폼 포털 배포 스크립트 실행
cd "$INSTALL_PATH"/workspace/container-platform/cp-portal-deployment/script || exit
chmod +x deploy-cp-portal.sh
./deploy-cp-portal.sh > deploy-portal-result.log

# Adding entries to Pod /etc/hosts with HostAliases
echo "Adding entries to Pod /etc/hosts with HostAliases"
kubectl patch deployment cp-portal-terraman-deployment   -n cp-portal --type "merge" -p '{"spec":{"template":{"spec":{"hostAliases":[{"ip":"'${PORTAL_HOST_IP}'","hostnames":["'${PORTAL_HOST_DOMAIN}'","vault.'${PORTAL_HOST_DOMAIN}'","harbor.'${PORTAL_HOST_DOMAIN}'","portal.'${PORTAL_HOST_DOMAIN}'","keycloak.'${PORTAL_PORTAL_HOST_DOMAIN}'"]},{"ip":"'${CLUSTER_ENDPOINT}'","hostnames":["'${PORTAL_MASTER_NODE_PUBLIC_IP}'"]}]}}}}'
kubectl patch deployment cp-portal-metric-api-deployment -n cp-portal --type "merge" -p '{"spec":{"template":{"spec":{"hostAliases":[{"ip":"'${PORTAL_HOST_IP}'","hostnames":["'${PORTAL_HOST_DOMAIN}'","vault.'${PORTAL_HOST_DOMAIN}'","harbor.'${PORTAL_HOST_DOMAIN}'","portal.'${PORTAL_HOST_DOMAIN}'","keycloak.'${PORTAL_HOST_DOMAIN}'"]},{"ip":"'${CLUSTER_ENDPOINT}'","hostnames":["'${PORTAL_MASTER_NODE_PUBLIC_IP}'"]}]}}}}'
kubectl patch deployment cp-portal-common-api-deployment -n cp-portal --type "merge" -p '{"spec":{"template":{"spec":{"hostAliases":[{"ip":"'${PORTAL_HOST_IP}'","hostnames":["'${PORTAL_HOST_DOMAIN}'","vault.'${PORTAL_HOST_DOMAIN}'","harbor.'${PORTAL_HOST_DOMAIN}'","portal.'${PORTAL_HOST_DOMAIN}'","keycloak.'${PORTAL_HOST_DOMAIN}'"]},{"ip":"'${CLUSTER_ENDPOINT}'","hostnames":["'${PORTAL_MASTER_NODE_PUBLIC_IP}'"]}]}}}}'
kubectl patch deployment cp-portal-api-deployment        -n cp-portal --type "merge" -p '{"spec":{"template":{"spec":{"hostAliases":[{"ip":"'${PORTAL_HOST_IP}'","hostnames":["'${PORTAL_HOST_DOMAIN}'","vault.'${PORTAL_HOST_DOMAIN}'","harbor.'${PORTAL_HOST_DOMAIN}'","portal.'${PORTAL_HOST_DOMAIN}'","keycloak.'${PORTAL_HOST_DOMAIN}'"]},{"ip":"'${CLUSTER_ENDPOINT}'","hostnames":["'${PORTAL_MASTER_NODE_PUBLIC_IP}'"]}]}}}}'
kubectl patch deployment cp-portal-ui-deployment         -n cp-portal --type "merge" -p '{"spec":{"template":{"spec":{"hostAliases":[{"ip":"'${PORTAL_HOST_IP}'","hostnames":["'${PORTAL_HOST_DOMAIN}'","vault.'${PORTAL_HOST_DOMAIN}'","harbor.'${PORTAL_HOST_DOMAIN}'","portal.'${PORTAL_HOST_DOMAIN}'","keycloak.'${PORTAL_HOST_DOMAIN}'"]},{"ip":"'${CLUSTER_ENDPOINT}'","hostnames":["'${PORTAL_MASTER_NODE_PUBLIC_IP}'"]}]}}}}'
kubectl patch deployment cp-keycloak                     -n keycloak  --type "merge" -p '{"spec":{"template":{"spec":{"hostAliases":[{"ip":"'${PORTAL_HOST_IP}'","hostnames":["'${PORTAL_HOST_DOMAIN}'","vault.'${PORTAL_HOST_DOMAIN}'","harbor.'${PORTAL_HOST_DOMAIN}'","portal.'${PORTAL_HOST_DOMAIN}'","keycloak.'${PORTAL_HOST_DOMAIN}'"]},{"ip":"'${CLUSTER_ENDPOINT}'","hostnames":["'${PORTAL_MASTER_NODE_PUBLIC_IP}'"]}]}}}}'
