#!/usr/bin/env bash
echo "========== 06.install_k-pass Portal START =========="
# https://github.com/K-PaaS/container-platform/blob/master/install-guide/portal/cp-portal-standalone-guide.md

# Global Variable Setting
source /vagrant/00.global_variable.sh

# Create Deployment file download directory
mkdir -p "$INSTALL_PATH"/workspace/container-platform
cd "$INSTALL_PATH"/workspace/container-platform || exit

# Download v1.7.0 Deployment file and check file path
wget --content-disposition https://nextcloud.k-paas.org/index.php/s/qrApL4sP5eC2WMX/download && tar -xvf cp-portal-deployment-v1.7.0.tar.gz

# [Fix] Make namespace creation idempotent in all scripts
echo "Patching scripts to handle existing namespaces..."
find "$INSTALL_PATH"/workspace/container-platform -name "*.sh" -type f -print0 | xargs -0 sed -i 's/kubectl create ns \([^ ]*\)/kubectl create ns \1 2>\/dev\/null || true/g'


# Define variables for Container Platform Portal
sed -i 's/{k8s master node public ip}/${PORTAL_MASTER_NODE_PUBLIC_IP}/g'      "$INSTALL_PATH"/workspace/container-platform/cp-portal-deployment/script/cp-portal-vars.sh
sed -i 's/{host domain}/${PORTAL_HOST_DOMAIN}/g'                              "$INSTALL_PATH"/workspace/container-platform/cp-portal-deployment/script/cp-portal-vars.sh
sed -i 's/HOST_CLUSTER_IAAS_TYPE=\"1\"/HOST_CLUSTER_IAAS_TYPE=\"2\"/g'        "$INSTALL_PATH"/workspace/container-platform/cp-portal-deployment/script/cp-portal-vars.sh
#sed -i 's/{container platform portal provider type}/standalone/g'             "$INSTALL_PATH"/workspace/container-platform/cp-portal-deployment/script/cp-portal-vars.sh

# ARM64 Architecture Support
if [ "$(uname -m)" = "aarch64" ]; then
    echo "ARM64 Architecture Support"

    # ============================================================
    # 1. ghcr.io/dasomel-k-pass에서 ARM64 이미지 사용 설정
    #    로컬 빌드 대신 GitHub Container Registry에서 pull
    # ============================================================
    echo ">>> Configuring ARM64 cp-portal images from ghcr.io/dasomel-k-pass..."

    GHCR_REGISTRY="ghcr.io/dasomel-k-pass"
    IMG_TAG="latest"

    # ghcr.io 이미지 매핑 (deployment name -> image name)
    declare -A GHCR_IMAGE_MAP=(
        ["cp-portal-api"]="cp-portal-api"
        ["cp-portal-ui"]="cp-portal-ui"
        ["cp-portal-common-api"]="cp-portal-common-api"
        ["cp-portal-catalog-api"]="cp-catalog-api"
        ["cp-portal-chaos-api"]="cp-chaos-api"
        ["cp-portal-chaos-collector"]="cp-chaos-collector"
        ["cp-portal-metric-api"]="cp-metrics-api"
        ["cp-portal-migration-api"]="cp-migration-api"
        ["cp-portal-migration-auth"]="cp-migration-auth-api"
        ["cp-portal-migration-ui"]="cp-migration-ui"
        ["cp-portal-remote-api"]="cp-remote-api"
        ["cp-portal-terraman"]="cp-terraman"
    )

    # ============================================================
    # 1-1. Helm values 파일 수정: ghcr.io/dasomel-k-pass 이미지 사용
    # ============================================================
    echo ">>> Modifying cp-portal values to use ghcr.io/dasomel-k-pass images..."

    CP_PORTAL_VALUES_ORIG="$INSTALL_PATH/workspace/container-platform/cp-portal-deployment/values_orig/cp-portal.yaml"

    if [ -f "$CP_PORTAL_VALUES_ORIG" ]; then
        # global.image.registry 변경
        sed -i 's|registry: {K_PAAS_REGISTRY}/{K_PAAS_REPO}|registry: ghcr.io/dasomel-k-pass|g' "$CP_PORTAL_VALUES_ORIG"

        # global.image.tag 변경 (latest 사용)
        sed -i 's|tag: {IMAGE_TAGS}|tag: latest|g' "$CP_PORTAL_VALUES_ORIG"

        # global.image.pullPolicy 변경 (Always로 ghcr.io에서 pull)
        sed -i 's|pullPolicy: {IMAGE_PULL_POLICY}|pullPolicy: Always|g' "$CP_PORTAL_VALUES_ORIG"

        # apps에서 개별 이미지 레지스트리 변경 (cp-portal-ui, cp-portal-migration-ui)
        sed -i 's|registry: {REPOSITORY_HOST}/{REPOSITORY_PROJECT_NAME}|registry: ghcr.io/dasomel-k-pass|g' "$CP_PORTAL_VALUES_ORIG"

        # 특정 이미지 이름 매핑 (ghcr.io naming convention)
        # cp-portal-catalog-api -> cp-catalog-api
        # cp-portal-chaos-api -> cp-chaos-api 등
        sed -i 's|name: cp-portal-catalog-api|name: cp-catalog-api|g' "$CP_PORTAL_VALUES_ORIG"
        sed -i 's|name: cp-portal-chaos-api|name: cp-chaos-api|g' "$CP_PORTAL_VALUES_ORIG"
        sed -i 's|name: cp-portal-chaos-collector|name: cp-chaos-collector|g' "$CP_PORTAL_VALUES_ORIG"
        sed -i 's|name: cp-portal-metric-api|name: cp-metrics-api|g' "$CP_PORTAL_VALUES_ORIG"
        sed -i 's|name: cp-portal-migration-api|name: cp-migration-api|g' "$CP_PORTAL_VALUES_ORIG"
        sed -i 's|name: cp-portal-migration-auth|name: cp-migration-auth-api|g' "$CP_PORTAL_VALUES_ORIG"
        sed -i 's|name: cp-portal-migration-ui|name: cp-migration-ui|g' "$CP_PORTAL_VALUES_ORIG"
        sed -i 's|name: cp-portal-remote-api|name: cp-remote-api|g' "$CP_PORTAL_VALUES_ORIG"
        sed -i 's|name: cp-portal-terraman|name: cp-terraman|g' "$CP_PORTAL_VALUES_ORIG"

        # Fix ConfigMap service URIs for ARM64 (service names also changed)
        # cp-portal-terraman-service -> cp-terraman-service
        # cp-portal-metric-api-service -> cp-metrics-api-service
        # cp-portal-chaos-collector-service -> cp-chaos-collector-service
        sed -i 's|cp-portal-terraman-service|cp-terraman-service|g' "$CP_PORTAL_VALUES_ORIG"
        sed -i 's|cp-portal-metric-api-service|cp-metrics-api-service|g' "$CP_PORTAL_VALUES_ORIG"
        sed -i 's|cp-portal-chaos-collector-service|cp-chaos-collector-service|g' "$CP_PORTAL_VALUES_ORIG"

        # Fix Ingress backend service names for ARM64
        # When app names change, service names also change in Helm templates
        # Ingress backends must reference the correct service names
        sed -i 's|cp-portal-catalog-api-service|cp-catalog-api-service|g' "$CP_PORTAL_VALUES_ORIG"
        sed -i 's|cp-portal-chaos-api-service|cp-chaos-api-service|g' "$CP_PORTAL_VALUES_ORIG"
        sed -i 's|cp-portal-migration-api-service|cp-migration-api-service|g' "$CP_PORTAL_VALUES_ORIG"
        sed -i 's|cp-portal-migration-auth-service|cp-migration-auth-api-service|g' "$CP_PORTAL_VALUES_ORIG"
        sed -i 's|cp-portal-migration-ui-service|cp-migration-ui-service|g' "$CP_PORTAL_VALUES_ORIG"
        sed -i 's|cp-portal-remote-api-service|cp-remote-api-service|g' "$CP_PORTAL_VALUES_ORIG"

        echo ">>> cp-portal values modified for ghcr.io/dasomel-k-pass"
    else
        echo "Warning: cp-portal values file not found: $CP_PORTAL_VALUES_ORIG"
    fi

    # ============================================================
    # 2. Harbor ARM64 설정: 공식 Harbor chart + ghcr.io/dasomel/goharbor ARM64 이미지
    # ============================================================
    echo ">>> Configuring Harbor for ARM64 with official Harbor chart"

    # ARM64용 원본 harbor.yaml 파일을 수정하여 ghcr.io/dasomel/goharbor 이미지 + latest 태그 사용
    HARBOR_VALUES_DST="$INSTALL_PATH/workspace/container-platform/cp-portal-deployment/values_orig/harbor.yaml"
    
    if [ -f "$HARBOR_VALUES_DST" ]; then
        echo ">>> Modifying harbor.yaml for ARM64 with ghcr.io/dasomel/goharbor images..."
        
        # 기존 파일 백업
        cp "$HARBOR_VALUES_DST" "$HARBOR_VALUES_DST.bak.orig" 2>/dev/null || true
        
        # 이미지 레포지토리를 ghcr.io/dasomel/goharbor로 변경
        sed -i 's|{K_PAAS_REGISTRY}/goharbor|ghcr.io/dasomel/goharbor|g' "$HARBOR_VALUES_DST"
        
        # 기존에 잘못 붙었을 수 있는 tag: latest 라인들 먼저 정리 (중복 방지)
        sed -i '/^[[:space:]]*tag: latest/d' "$HARBOR_VALUES_DST"
        
        # 각 repository 라인 바로 아래에 동일한 들여쓰기로 tag: latest 추가
        # 4칸 들여쓰기된 repository (nginx, portal, core 등)
        sed -i '/^    repository:.*goharbor/a\    tag: latest' "$HARBOR_VALUES_DST"
        # 6칸 들여쓰기된 repository (registry, database, redis 내부)
        sed -i '/^      repository:.*goharbor/a\      tag: latest' "$HARBOR_VALUES_DST"
        
        # 만약 원본에 이미 tag: vX.X.X 가 있었다면 latest로 변경
        sed -i 's/tag: v2\..*/tag: latest/g' "$HARBOR_VALUES_DST"
        
        echo ">>> Harbor values modified with ghcr.io/dasomel/goharbor and latest tags"
        grep -A1 "repository:.*goharbor" "$HARBOR_VALUES_DST" | head -n 20
        
        # imagePullPolicy 추가 (없으면 추가)
        # if ! grep -q "imagePullPolicy:" "$HARBOR_VALUES_DST"; then
        #     sed -i '/^expose:/i imagePullPolicy: Always' "$HARBOR_VALUES_DST"
        # fi
        
        echo ">>> Harbor values modified: $HARBOR_VALUES_DST"
    else
        echo "ERROR: Harbor values file not found: $HARBOR_VALUES_DST"
        exit 1
    fi

    echo ">>> Applying hotfix for Harbor ARM64 images (registry and registryctl)..."
    HOTFIX_DIR="/tmp/harbor-hotfix"
    rm -rf "$HOTFIX_DIR"
    mkdir -p "$HOTFIX_DIR"

    # Common install_cert.sh (required by both registry and registryctl)
    cat > "$HOTFIX_DIR/install_cert.sh" << 'EOF'
#!/usr/bin/env bash
echo "Certificate installation wrapper"
if [ -f "/etc/registry/ssl/ca.crt" ]; then
    cp /etc/registry/ssl/ca.crt /usr/local/share/ca-certificates/
    update-ca-certificates
fi
EOF
    chmod +x "$HOTFIX_DIR/install_cert.sh"

    # Fix registry-photon: Permission denied on entrypoint.sh + missing install_cert.sh
    echo ">>> Patching registry-photon image..."
    cat > "$HOTFIX_DIR/Dockerfile.registry" << DOCKERFILE_EOF
FROM ghcr.io/dasomel/goharbor/registry-photon:latest
USER root
COPY install_cert.sh /home/harbor/install_cert.sh
RUN chmod +x /home/harbor/entrypoint.sh /home/harbor/install_cert.sh
USER harbor
DOCKERFILE_EOF
    sudo podman build --no-cache --arch=arm64 -t ghcr.io/dasomel/goharbor/registry-photon:latest-fixed -f "$HOTFIX_DIR/Dockerfile.registry" "$HOTFIX_DIR"
    sudo podman tag ghcr.io/dasomel/goharbor/registry-photon:latest-fixed ghcr.io/dasomel/goharbor/registry-photon:latest

    # Fix harbor-registryctl: missing install_cert.sh + binary path symlink
    echo ">>> Patching harbor-registryctl image..."
    cat > "$HOTFIX_DIR/Dockerfile.registryctl" << DOCKERFILE_EOF
FROM ghcr.io/dasomel/goharbor/harbor-registryctl:latest
USER root
COPY install_cert.sh /home/harbor/install_cert.sh
# Link binary from /harbor to /home/harbor as expected by start.sh
RUN ln -s /harbor/harbor_registryctl /home/harbor/harbor_registryctl && \
    chmod +x /home/harbor/install_cert.sh
USER harbor
DOCKERFILE_EOF
    sudo podman build --no-cache --arch=arm64 -t ghcr.io/dasomel/goharbor/harbor-registryctl:latest-fixed -f "$HOTFIX_DIR/Dockerfile.registryctl" "$HOTFIX_DIR"
    sudo podman tag ghcr.io/dasomel/goharbor/harbor-registryctl:latest-fixed ghcr.io/dasomel/goharbor/harbor-registryctl:latest

    # Distribute fixed images to worker nodes
    echo ">>> Distributing fixed Harbor images to worker nodes..."
    FIXED_IMAGES=(
        "ghcr.io/dasomel/goharbor/registry-photon:latest"
        "ghcr.io/dasomel/goharbor/harbor-registryctl:latest"
    )

    # Use BatchMode and SSH key to avoid password prompt
    SSH_OPTS="-o StrictHostKeyChecking=no -o BatchMode=yes -i /home/vagrant/.ssh/id_rsa"

    for img in "${FIXED_IMAGES[@]}"; do
        img_basename=$(echo "$img" | sed 's|/|_|g; s|:|_|g')
        tar_path="/tmp/${img_basename}.tar"
        rm -f "$tar_path"
        echo "  Exporting $img..."
        sudo podman save -o "$tar_path" "$img"

        for node in ${WORKER01} ${WORKER02}; do
            if [ -n "$node" ]; then
                echo "  Copying to $node..."
                scp $SSH_OPTS "$tar_path" vagrant@"$node":/tmp/
                ssh $SSH_OPTS vagrant@"$node" "sudo podman load -i /tmp/${img_basename}.tar && rm -f /tmp/${img_basename}.tar"
            fi
        done
        rm -f "$tar_path"
    done

    # ============================================================
    # 3. Keycloak: MariaDB 연결 설정 및 호환성 수정
    # ============================================================
    echo ">>> Configuring Keycloak for MariaDB connection"

    # Keycloak realm JSON에서 Keycloak 24.0.5와 호환되지 않는 필드 제거
    echo ">>> Removing incompatible fields from realm JSON..."
    REALM_JSON="$INSTALL_PATH/workspace/container-platform/cp-portal-deployment/values_orig/cp-realm-realm.json"
    if [ -f "$REALM_JSON" ]; then
        # Remove Keycloak 24.0.5 incompatible fields (exported from Keycloak 26.x)
        sed -i '/"bruteForceStrategy"/d' "$REALM_JSON"
        sed -i '/"organizationsEnabled"/d' "$REALM_JSON"
        sed -i '/"verifiableCredentialsEnabled"/d' "$REALM_JSON"
        sed -i '/"adminPermissionsEnabled"/d' "$REALM_JSON"
    fi

    # Keycloak values 수정
    KEYCLOAK_YAML="$INSTALL_PATH/workspace/container-platform/cp-portal-deployment/values_orig/keycloak.yaml"
    if [ -f "$KEYCLOAK_YAML" ]; then
        echo ">>> Patching keycloak.yaml for MariaDB connection..."

        # 1. extraStartupArgs에 hostname 옵션 추가 (issuer URL 문제 해결)
        sed -i 's/extraStartupArgs: "--import-realm"/extraStartupArgs: "--import-realm --hostname={KEYCLOAK_HOST} --hostname-strict=false --hostname-strict-https=false"/' "$KEYCLOAK_YAML"

        # 2. Bitnami entrypoint용 KEYCLOAK_DATABASE_* 환경변수 추가 (externalDatabase는 PostgreSQL 전용)
        sed -i '/extraEnvVars:/a\
  # Bitnami entrypoint용 MariaDB 연결 설정\
  - name: KEYCLOAK_DATABASE_VENDOR\
    value: "{KEYCLOAK_DB_VENDOR}"\
  - name: KEYCLOAK_DATABASE_HOST\
    value: "{DATABASE_HOST}"\
  - name: KEYCLOAK_DATABASE_PORT\
    value: "{DATABASE_PORT}"\
  - name: KEYCLOAK_DATABASE_NAME\
    value: "{KEYCLOAK_DB_SCHEMA}"\
  - name: KEYCLOAK_DATABASE_USER\
    value: "{DATABASE_USER_ID}"\
  - name: KEYCLOAK_DATABASE_PASSWORD\
    value: "{DATABASE_USER_PASSWORD}"' "$KEYCLOAK_YAML"

        # 3. externalDatabase 섹션 제거 (PostgreSQL 전용이므로 MariaDB에서는 사용 안함)
        sed -i '/^externalDatabase:/,/password: {DATABASE_USER_PASSWORD}$/d' "$KEYCLOAK_YAML"

        echo ">>> keycloak.yaml patched for MariaDB"
    fi

    # ============================================================
    # 4. ghcr.io 이미지 사용 시 inject_cert_and_build_image 스킵
    #    대신 init container로 런타임에 인증서 주입
    # ============================================================
    echo ">>> Skipping inject_cert_and_build_image for ghcr.io images"
    DEPLOY_SCRIPT="$INSTALL_PATH/workspace/container-platform/cp-portal-deployment/script/deploy-cp-portal.sh"

    # inject_cert_and_build_image 함수를 no-op으로 교체
    sed -i '/^inject_cert_and_build_image() {$/,/^}$/c\
inject_cert_and_build_image() {\
  echo "[ghcr.io] Skipping cert injection - will use init container at runtime"\
}' "$DEPLOY_SCRIPT"

    # ============================================================
    # 5. deploy-cp-portal.sh에서 Keycloak helm_install 스킵
    #    - 기존 deploy-cp-portal.sh는 잘못된 설정으로 배포 시도함
    #    - 스크립트 하단에서 올바른 설정으로 명시적 배포 수행
    # ============================================================
    echo ">>> Patching deploy-cp-portal.sh to skip Keycloak helm_install on ARM64"
    # helm_install 3 호출을 주석 처리 (Keycloak)
    sed -i 's/^[[:space:]]*helm_install 3$/  # [ARM64 SKIP] helm_install 3  # Keycloak deployed manually later/' "$DEPLOY_SCRIPT"

    # ============================================================
    # 6. deploy-cp-portal.sh에서 terraman 라벨 수정
    #    - ghcr.io 이미지 이름 변경으로 인해 라벨도 변경됨
    #    - cp-portal-terraman -> cp-terraman
    # ============================================================
    echo ">>> Patching deploy-cp-portal.sh to fix terraman label for ARM64"
    sed -i 's/app=\$APP_TERRAMAN/app=cp-terraman/g' "$DEPLOY_SCRIPT"
fi

# container(cri-o) mirror setting
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

sudo systemctl restart crio

# Fix cp-cert-setup script for cri-o (not containerd)
echo ">>> Fixing cp-cert-setup configmap script for cri-o..."
cat > "$INSTALL_PATH"/workspace/container-platform/cp-portal-deployment/values_orig/cp-cert-setup.yaml << 'EOF'
# Default values for container platform certificate setup.
# This is a YAML-formatted file.
# Declare variables to be passed into your templates.
metadata:
  name: cp-cert-setup
  namespace: kube-system

data:
  target:
    cert: cert
    script: echo "$CA_CERT" > /usr/local/share/ca-certificates/{HOST_DOMAIN}.crt && update-ca-certificates && for cr in crio containerd; do if systemctl list-unit-files --type=service | grep -q "^${cr}.service"; then systemctl restart "$cr"; fi; done
EOF

if [ "$(uname -m)" = "aarch64" ]; then
    echo ">>> Patching MariaDB values for ARM64 (Downgrade to 10.11 & AIO off)..."
    MARIADB_VALUES="$INSTALL_PATH/workspace/container-platform/cp-portal-deployment/values_orig/mariadb.yaml"
    if [ -f "$MARIADB_VALUES" ]; then
        # Downgrade tag and set bind-address
        sed -i 's/repository: bitnamilegacy\/mariadb/repository: bitnamilegacy\/mariadb\n  tag: 10.11.8-debian-12-r0/' "$MARIADB_VALUES"
        # Disable Native AIO
        sed -i '/\[mysqld\]/a \    innodb_use_native_aio=0' "$MARIADB_VALUES"
        # Bind to 0.0.0.0 for safety
        sed -i 's/bind-address=\*/bind-address=0.0.0.0/' "$MARIADB_VALUES"
        # Increase packet size
        sed -i 's/16M/128M/' "$MARIADB_VALUES"
        echo ">>> MariaDB values patched."
    else
        echo "Warning: MariaDB values file not found at $MARIADB_VALUES"
    fi
    
    # Patch initdb configmap as well
    MARIADB_CONFIGMAP="$INSTALL_PATH/workspace/container-platform/cp-portal-deployment/values_orig/mariadb-configmap.yaml"
    if [ -f "$MARIADB_CONFIGMAP" ]; then
        sed -i 's/max_allowed_packet=16M/max_allowed_packet=128M/' "$MARIADB_CONFIGMAP"
    fi
fi

# Execute the Container Platform Portal deployment script
cd "$INSTALL_PATH"/workspace/container-platform/cp-portal-deployment/script || exit
chmod +x deploy-cp-portal.sh
./deploy-cp-portal.sh > deploy-portal-result.log

# ============================================================
# OpenBao Unseal Key Management
# Save unseal keys to Kubernetes secret for future use
# This ensures OpenBao can be unsealed after pod restarts
# ============================================================
echo ">>> Managing OpenBao unseal keys..."

# Wait for OpenBao pod to be ready
echo ">>> Waiting for OpenBao pod..."
kubectl wait --for=condition=Ready pod/openbao-0 -n openbao --timeout=120s 2>/dev/null || true

# Check if OpenBao is initialized
OPENBAO_STATUS=$(kubectl exec openbao-0 -n openbao -- bao status -format=json 2>/dev/null || echo '{}')
OPENBAO_INITIALIZED=$(echo "$OPENBAO_STATUS" | jq -r '.initialized // false')
OPENBAO_SEALED=$(echo "$OPENBAO_STATUS" | jq -r '.sealed // true')

echo ">>> OpenBao status - Initialized: $OPENBAO_INITIALIZED, Sealed: $OPENBAO_SEALED"

# Check if unseal keys exist in Kubernetes secret
UNSEAL_SECRET_EXISTS=$(kubectl get secret openbao-unseal-keys -n openbao -o name 2>/dev/null || echo "")

if [ "$OPENBAO_INITIALIZED" = "true" ] && [ "$OPENBAO_SEALED" = "true" ]; then
    echo ">>> OpenBao is sealed, attempting to unseal..."

    if [ -n "$UNSEAL_SECRET_EXISTS" ]; then
        # Get unseal keys from secret
        UNSEAL_KEY1=$(kubectl get secret openbao-unseal-keys -n openbao -o jsonpath='{.data.unseal_key_1}' | base64 -d)
        UNSEAL_KEY2=$(kubectl get secret openbao-unseal-keys -n openbao -o jsonpath='{.data.unseal_key_2}' | base64 -d)

        # Unseal OpenBao
        kubectl exec openbao-0 -n openbao -- bao operator unseal "$UNSEAL_KEY1" 2>/dev/null || true
        kubectl exec openbao-0 -n openbao -- bao operator unseal "$UNSEAL_KEY2" 2>/dev/null || true

        echo ">>> OpenBao unsealed using saved keys"
    else
        # Try to get keys from deploy-secmg result file
        UNSEAL_KEY_FILE="$INSTALL_PATH/workspace/container-platform/cp-portal-deployment/secmg/unseal-key"
        if [ -f "$UNSEAL_KEY_FILE" ]; then
            echo ">>> Found unseal keys file, extracting keys..."
            # Parse keys from the file and create secret
            KEYS=$(cat "$UNSEAL_KEY_FILE" | tr -d '"' | tr ',' '\n' | grep -oE '[A-Za-z0-9+/=]{40,}')
            KEY_ARR=($KEYS)

            if [ ${#KEY_ARR[@]} -ge 2 ]; then
                # Save keys to Kubernetes secret
                kubectl create secret generic openbao-unseal-keys -n openbao \
                    --from-literal=unseal_key_1="${KEY_ARR[0]}" \
                    --from-literal=unseal_key_2="${KEY_ARR[1]}" \
                    --from-literal=unseal_key_3="${KEY_ARR[2]:-}" 2>/dev/null || true

                # Unseal OpenBao
                kubectl exec openbao-0 -n openbao -- bao operator unseal "${KEY_ARR[0]}" 2>/dev/null || true
                kubectl exec openbao-0 -n openbao -- bao operator unseal "${KEY_ARR[1]}" 2>/dev/null || true

                echo ">>> OpenBao unsealed and keys saved to secret"
            fi
        else
            echo "WARNING: OpenBao is sealed but no unseal keys found"
            echo "You may need to reinitialize OpenBao or manually provide unseal keys"
        fi
    fi
elif [ "$OPENBAO_INITIALIZED" = "true" ] && [ "$OPENBAO_SEALED" = "false" ]; then
    # OpenBao is already unsealed, save keys to secret if not already saved
    if [ -z "$UNSEAL_SECRET_EXISTS" ]; then
        UNSEAL_KEY_FILE="$INSTALL_PATH/workspace/container-platform/cp-portal-deployment/secmg/unseal-key"
        if [ -f "$UNSEAL_KEY_FILE" ]; then
            echo ">>> Saving unseal keys to Kubernetes secret..."
            KEYS=$(cat "$UNSEAL_KEY_FILE" | tr -d '"' | tr ',' '\n' | grep -oE '[A-Za-z0-9+/=]{40,}')
            KEY_ARR=($KEYS)

            if [ ${#KEY_ARR[@]} -ge 2 ]; then
                kubectl create secret generic openbao-unseal-keys -n openbao \
                    --from-literal=unseal_key_1="${KEY_ARR[0]}" \
                    --from-literal=unseal_key_2="${KEY_ARR[1]}" \
                    --from-literal=unseal_key_3="${KEY_ARR[2]:-}" 2>/dev/null || true
                echo ">>> Unseal keys saved to openbao-unseal-keys secret"
            fi
        fi
    fi
    echo ">>> OpenBao is already initialized and unsealed"
fi

# Verify OpenBao is unsealed
FINAL_STATUS=$(kubectl exec openbao-0 -n openbao -- bao status -format=json 2>/dev/null || echo '{}')
FINAL_SEALED=$(echo "$FINAL_STATUS" | jq -r '.sealed // true')
if [ "$FINAL_SEALED" = "false" ]; then
    echo ">>> OpenBao is ready (unsealed)"
else
    echo "WARNING: OpenBao may still be sealed. Check logs and unseal manually if needed."
fi

# ============================================================
# Fix OpenBao Secret Key Naming: Use camelCase instead of snake_case
# Java Clusters class expects camelCase properties (clusterToken, clusterApiUrl)
# but Vault secrets were created with snake_case keys (cluster_token, cluster_api_url)
# Jackson JSON deserialization fails with mismatched key names
# ============================================================
echo ">>> Verifying OpenBao cluster secrets use camelCase keys..."

# Get OpenBao root token
OPENBAO_ROOT_TOKEN=$(kubectl get secret openbao-unseal-keys -n openbao -o jsonpath='{.data.root_token}' 2>/dev/null | base64 -d || \
    cat "$INSTALL_PATH/workspace/container-platform/cp-portal-deployment/secmg/root-token" 2>/dev/null | tr -d '"' || \
    echo "")

if [ -n "$OPENBAO_ROOT_TOKEN" ]; then
    OPENBAO_IP=$(kubectl get svc openbao -n openbao -o jsonpath='{.spec.clusterIP}')
    export BAO_ADDR="http://${OPENBAO_IP}:8200"
    export BAO_TOKEN="$OPENBAO_ROOT_TOKEN"

    # Check and fix cluster secrets
    echo ">>> Checking cluster secrets in OpenBao..."
    CLUSTER_LIST=$(kubectl exec openbao-0 -n openbao -- bao kv list -format=json secret/cluster 2>/dev/null || echo '[]')

    for CLUSTER_ID in $(echo "$CLUSTER_LIST" | jq -r '.[]' 2>/dev/null); do
        echo ">>> Checking cluster: $CLUSTER_ID"
        SECRET_DATA=$(kubectl exec openbao-0 -n openbao -- bao kv get -format=json "secret/cluster/$CLUSTER_ID" 2>/dev/null || echo '{}')

        # Check if snake_case keys exist
        HAS_SNAKE_CASE=$(echo "$SECRET_DATA" | jq -r '.data.data.cluster_token // empty')

        if [ -n "$HAS_SNAKE_CASE" ]; then
            echo ">>> Found snake_case keys, converting to camelCase..."
            CLUSTER_TOKEN=$(echo "$SECRET_DATA" | jq -r '.data.data.cluster_token // empty')
            CLUSTER_API_URL=$(echo "$SECRET_DATA" | jq -r '.data.data.cluster_api_url // empty')

            # Write with camelCase keys
            kubectl exec openbao-0 -n openbao -- bao kv put "secret/cluster/$CLUSTER_ID" \
                clusterApiUrl="$CLUSTER_API_URL" \
                clusterToken="$CLUSTER_TOKEN" 2>/dev/null || \
                echo "Warning: Failed to update cluster secret for $CLUSTER_ID"
            echo ">>> Updated cluster $CLUSTER_ID with camelCase keys"
        else
            echo ">>> Cluster $CLUSTER_ID already uses correct key format"
        fi
    done
else
    echo "WARNING: Could not retrieve OpenBao root token. Cluster secrets may need manual verification."
    echo "Ensure cluster secrets use camelCase keys: clusterApiUrl, clusterToken"
fi

# ============================================================
# ARM64: Init Container로 SSL 인증서 주입 설정
# ghcr.io 이미지를 사용하고 런타임에 인증서를 Java truststore에 추가
# ============================================================
if [ "$(uname -m)" = "aarch64" ]; then
    echo ">>> Configuring init container for SSL certificate injection..."

    # UI Deployment들에 init container 추가하여 인증서 주입
    UI_DEPLOYMENTS=("cp-portal-ui-deployment" "cp-portal-migration-ui-deployment")
    GHCR_REGISTRY="ghcr.io/dasomel-k-pass"

    for deploy in "${UI_DEPLOYMENTS[@]}"; do
        # deployment 이름에서 container 이름 추출
        container_name=$(echo "$deploy" | sed 's/-deployment$//')

        # ghcr.io 이미지 이름 매핑
        if [ "$container_name" = "cp-portal-ui" ]; then
            ghcr_image="${GHCR_REGISTRY}/cp-portal-ui:latest"
        elif [ "$container_name" = "cp-portal-migration-ui" ]; then
            ghcr_image="${GHCR_REGISTRY}/cp-migration-ui:latest"
        fi

        echo ">>> Patching $deploy with init container for cert injection..."

        # Deployment 패치: init container + volume 추가
        kubectl patch deployment "$deploy" -n cp-portal --type='json' -p="[
            {\"op\": \"add\", \"path\": \"/spec/template/spec/initContainers\", \"value\": [{
                \"name\": \"import-cert\",
                \"image\": \"eclipse-temurin:17-jdk-jammy\",
                \"command\": [\"/bin/bash\", \"-c\"],
                \"args\": [\"cp \$JAVA_HOME/lib/security/cacerts /cacerts/cacerts && chmod 644 /cacerts/cacerts && keytool -importcert -noprompt -trustcacerts -alias k-paas-io -file /certs/tls.crt -keystore /cacerts/cacerts -storepass changeit && echo Certificate imported successfully\"],
                \"volumeMounts\": [
                    {\"name\": \"tls-cert\", \"mountPath\": \"/certs\", \"readOnly\": true},
                    {\"name\": \"cacerts-volume\", \"mountPath\": \"/cacerts\"}
                ],
                \"securityContext\": {\"runAsUser\": 0}
            }]},
            {\"op\": \"add\", \"path\": \"/spec/template/spec/volumes\", \"value\": [
                {\"name\": \"tls-cert\", \"secret\": {\"secretName\": \"k-paas.io-tls\"}},
                {\"name\": \"cacerts-volume\", \"emptyDir\": {}}
            ]},
            {\"op\": \"replace\", \"path\": \"/spec/template/spec/containers/0/image\", \"value\": \"${ghcr_image}\"},
            {\"op\": \"replace\", \"path\": \"/spec/template/spec/containers/0/imagePullPolicy\", \"value\": \"Always\"},
            {\"op\": \"add\", \"path\": \"/spec/template/spec/containers/0/env\", \"value\": [
                {\"name\": \"JAVA_TOOL_OPTIONS\", \"value\": \"-Djavax.net.ssl.trustStore=/cacerts/cacerts -Djavax.net.ssl.trustStorePassword=changeit\"}
            ]},
            {\"op\": \"add\", \"path\": \"/spec/template/spec/containers/0/volumeMounts\", \"value\": [
                {\"name\": \"cacerts-volume\", \"mountPath\": \"/cacerts\", \"readOnly\": true}
            ]}
        ]" 2>/dev/null || echo "Warning: Failed to patch $deploy, may need manual configuration"
    done

    # 나머지 deployment들도 ghcr.io 이미지 사용하도록 변경
    echo ">>> Updating all cp-portal deployments to use ghcr.io images..."

    declare -A DEPLOY_IMAGE_MAP=(
        ["cp-portal-api-deployment"]="${GHCR_REGISTRY}/cp-portal-api:latest"
        ["cp-portal-common-api-deployment"]="${GHCR_REGISTRY}/cp-portal-common-api:latest"
        ["cp-portal-catalog-api-deployment"]="${GHCR_REGISTRY}/cp-catalog-api:latest"
        ["cp-portal-chaos-api-deployment"]="${GHCR_REGISTRY}/cp-chaos-api:latest"
        ["cp-portal-chaos-collector-deployment"]="${GHCR_REGISTRY}/cp-chaos-collector:latest"
        ["cp-portal-metric-api-deployment"]="${GHCR_REGISTRY}/cp-metrics-api:latest"
        ["cp-portal-migration-api-deployment"]="${GHCR_REGISTRY}/cp-migration-api:latest"
        ["cp-portal-migration-auth-deployment"]="${GHCR_REGISTRY}/cp-migration-auth-api:latest"
        ["cp-portal-remote-api-deployment"]="${GHCR_REGISTRY}/cp-remote-api:latest"
        ["cp-portal-terraman-deployment"]="${GHCR_REGISTRY}/cp-terraman:latest"
    )

    for deploy in "${!DEPLOY_IMAGE_MAP[@]}"; do
        new_image="${DEPLOY_IMAGE_MAP[$deploy]}"
        container_name=$(echo "$deploy" | sed 's/-deployment$//')

        echo "  Updating $deploy -> $new_image"
        kubectl set image "deployment/${deploy}" "${container_name}=${new_image}" -n cp-portal 2>/dev/null || true
        kubectl patch deployment "$deploy" -n cp-portal --type='json' -p="[
            {\"op\": \"replace\", \"path\": \"/spec/template/spec/containers/0/imagePullPolicy\", \"value\": \"Always\"}
        ]" 2>/dev/null || true
    done
fi

# ============================================================
# ARM64: MariaDB cp-admin 인증 방식 변경 (Keycloak JDBC 호환성)
# ed25519 인증은 일부 JDBC 드라이버에서 지원하지 않음
# ============================================================
if [ "$(uname -m)" = "aarch64" ]; then
    echo ">>> Configuring MariaDB cp-admin for mysql_native_password authentication..."
    kubectl exec -n mariadb mariadb-0 -- mariadb -uroot -pcpAdmin!12345 -e "
        ALTER USER 'cp-admin'@'%' IDENTIFIED VIA mysql_native_password USING PASSWORD('cpAdmin!12345');
        FLUSH PRIVILEGES;
    " 2>/dev/null || echo "Warning: Failed to change cp-admin auth method (may already be correct)"

    # ============================================================
    # ARM64: Keycloak 배포 (Bitnami Helm chart + MariaDB)
    # deploy-cp-portal.sh에서 스킵했으므로 여기서 배포
    # ============================================================
    echo ">>> Deploying Keycloak for ARM64..."
    
    # 1. MariaDB 준비 대기
    echo ">>> Waiting for MariaDB to be ready..."
    for i in {1..30}; do
        if kubectl get statefulset/mariadb -n mariadb 2>/dev/null | grep -q "1/1"; then
            echo ">>> MariaDB is ready"
            break
        fi
        echo ">>> Waiting for MariaDB... ($i/30)"
        sleep 10
    done

    # 추가로 pod 상태 확인
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=mariadb -n mariadb --timeout=300s 2>/dev/null || {
        echo "Warning: MariaDB pod wait timeout, checking status..."
        kubectl get pods -n mariadb
    }
    
    # 2. Keycloak 네임스페이스 및 TLS 생성
    echo ">>> Creating Keycloak namespace and TLS secret..."
    kubectl create ns keycloak 2>/dev/null || true
    
    # TLS Secret 생성
    CERTS_DIR="$INSTALL_PATH/workspace/container-platform/cp-portal-deployment/certs"
    if [ -f "$CERTS_DIR/${PORTAL_HOST_DOMAIN}.crt" ] && [ -f "$CERTS_DIR/${PORTAL_HOST_DOMAIN}.key" ]; then
        kubectl create secret tls "${PORTAL_HOST_DOMAIN}-tls" \
            --cert="$CERTS_DIR/${PORTAL_HOST_DOMAIN}.crt" \
            --key="$CERTS_DIR/${PORTAL_HOST_DOMAIN}.key" \
            -n keycloak --dry-run=client -o yaml | kubectl apply -f -
        echo ">>> TLS secret created in keycloak namespace"
    else
        echo "ERROR: TLS certificates not found in $CERTS_DIR"
        echo "Expected files: ${PORTAL_HOST_DOMAIN}.crt, ${PORTAL_HOST_DOMAIN}.key"
        ls -la "$CERTS_DIR" || true
        exit 1
    fi

    # 3. ConfigMap 확인 (cp-realm)
    if ! kubectl get configmap cp-realm -n keycloak 2>/dev/null; then
        echo "ERROR: cp-realm ConfigMap not found in keycloak namespace"
        echo "The ConfigMap should have been created by deploy-cp-portal.sh"
        exit 1
    fi

    # 4. 기존 Keycloak 정리 (혹시 모를 잔재)
    echo ">>> Cleaning up any existing Keycloak installation..."
    helm uninstall keycloak -n keycloak 2>/dev/null || true
    kubectl delete pvc --all -n keycloak 2>/dev/null || true
    sleep 5
    
    # 5. Keycloak values 파일 생성
    KEYCLOAK_VALUES="$INSTALL_PATH/workspace/container-platform/cp-portal-deployment/values/keycloak.yaml"
    mkdir -p "$(dirname "$KEYCLOAK_VALUES")"
    echo ">>> Generating Keycloak values file: $KEYCLOAK_VALUES"
    cat > "$KEYCLOAK_VALUES" << 'KEYCLOAK_YAML_EOF'
global:
  security:
    allowInsecureImages: true

image:
  registry: docker.io
  repository: bitnamilegacy/keycloak
  tag: 26.3.3-debian-12-r0

auth:
  adminUser: admin
  adminPassword: admin

tls:
  enabled: false

production: true
proxyHeaders: xforwarded
extraStartupArgs: "--import-realm --hostname-strict=false"

resources:
  requests:
    cpu: 300m
    memory: 512Mi
  limits:
    cpu: 750m
    memory: 1Gi

podSecurityContext:
  enabled: true
  fsGroup: 1001

containerSecurityContext:
  enabled: true
  runAsUser: 1001
  runAsGroup: 1001
  runAsNonRoot: true
  privileged: false
  allowPrivilegeEscalation: false
  seccompProfile:
    type: RuntimeDefault

# Dummy externalDatabase to pass Bitnami chart validation
# Actual DB connection is overridden by KC_DB_* env vars below
externalDatabase:
  host: mariadb.mariadb.svc.cluster.local
  port: 3306
  database: keycloak
  user: cp-admin
  password: "cpAdmin!12345"

extraEnvVars:
  - name: KC_DB
    value: mariadb
  - name: KC_DB_SCHEMA
    value: keycloak
  - name: KC_DB_URL
    value: "jdbc:mariadb://mariadb.mariadb.svc.cluster.local:3306/keycloak"
  - name: KC_DB_USERNAME
    value: cp-admin
  - name: KC_DB_PASSWORD
    value: "cpAdmin!12345"
  - name: KC_PROXY
    value: edge
  - name: KC_HTTP_ENABLED
    value: "true"

replicaCount: 1

extraVolumes:
  - name: cp-realm
    configMap:
      name: cp-realm
extraVolumeMounts:
  - name: cp-realm
    mountPath: /opt/bitnami/keycloak/data/import/cp-realm-realm.json
    subPath: cp-realm-realm.json

ingress:
  enabled: true
  ingressClassName: nginx
  hostname: keycloak.k-paas.io
  annotations:
    nginx.ingress.kubernetes.io/proxy-body-size: 2500m
    nginx.ingress.kubernetes.io/proxy-buffer-size: 12k
  tls: true
  selfSigned: false
  extraTls:
    - hosts:
        - keycloak.k-paas.io
      secretName: k-paas.io-tls

postgresql:
  enabled: false
KEYCLOAK_YAML_EOF

    # Replace MariaDB service name with ClusterIP
    MARIADB_CLUSTERIP=$(kubectl get svc mariadb -n mariadb -o jsonpath='{.spec.clusterIP}')
    if [ -n "$MARIADB_CLUSTERIP" ]; then
        echo ">>> Replacing MariaDB service name with ClusterIP: $MARIADB_CLUSTERIP"
        sed -i "s|mariadb.mariadb.svc.cluster.local|${MARIADB_CLUSTERIP}|g" "$KEYCLOAK_VALUES"
    fi

    # Keycloak 재배포
    echo ">>> Installing Keycloak with Helm..."
    CHARTS_DIR="$INSTALL_PATH/workspace/container-platform/cp-portal-deployment/charts"
    helm install keycloak "$CHARTS_DIR/keycloak-25.2.0.tgz" \
        -f "$KEYCLOAK_VALUES" \
        -n keycloak \
        --wait --timeout 5m || echo "Warning: Keycloak helm install may have issues"
    
    echo ">>> Waiting for Keycloak to be ready..."
    kubectl rollout status statefulset/keycloak -n keycloak --timeout=300s 2>/dev/null || {
        echo "Warning: Keycloak may still be starting up"
        echo "Check logs with: kubectl logs -n keycloak keycloak-0"
    }
fi

# Fix: Create harbor.k-paas.io-tls secret for Harbor core component
echo "Creating harbor.k-paas.io-tls secret for Harbor..."
kubectl get secret k-paas.io-tls -n harbor -o yaml 2>/dev/null | \
  sed 's/name: k-paas.io-tls/name: harbor.k-paas.io-tls/' | \
  kubectl apply -f - 2>/dev/null || echo "Harbor TLS secret already exists or Harbor not deployed"

# Adding entries to Pod /etc/hosts with HostAliases
# NOTE: Deployment names vary - some use 'cp-portal-*', others use 'cp-*' without 'portal'
echo "Adding entries to Pod /etc/hosts with HostAliases"

# Define hostAliases JSON patch (reusable)
HOSTALIAS_PATCH='{"spec":{"template":{"spec":{"hostAliases":[{"ip":"'${PORTAL_HOST_IP}'","hostnames":["'${PORTAL_HOST_DOMAIN}'","vault.'${PORTAL_HOST_DOMAIN}'","harbor.'${PORTAL_HOST_DOMAIN}'","portal.'${PORTAL_HOST_DOMAIN}'","keycloak.'${PORTAL_HOST_DOMAIN}'","openbao.'${PORTAL_HOST_DOMAIN}'","chartmuseum.'${PORTAL_HOST_DOMAIN}'"]},{"ip":"'${CLUSTER_ENDPOINT}'","hostnames":["'${PORTAL_MASTER_NODE_PUBLIC_IP}'"]}]}}}}'

# Patch all deployments with hostAliases
for dep in \
    cp-portal-api-deployment \
    cp-portal-common-api-deployment \
    cp-portal-ui-deployment \
    cp-catalog-api-deployment \
    cp-chaos-api-deployment \
    cp-chaos-collector-deployment \
    cp-metrics-api-deployment \
    cp-migration-api-deployment \
    cp-migration-auth-api-deployment \
    cp-migration-ui-deployment \
    cp-remote-api-deployment \
    cp-terraman-deployment
do
    echo ">>> Patching hostAliases for ${dep}..."
    kubectl patch deployment ${dep} -n cp-portal --type "merge" -p "${HOSTALIAS_PATCH}" 2>/dev/null || echo ">>> Skipped ${dep} (may not exist yet)"
done
# Keycloak uses StatefulSet (not Deployment) in Bitnami Helm chart
kubectl patch statefulset keycloak -n keycloak --type "merge" -p '{"spec":{"template":{"spec":{"hostAliases":[{"ip":"'${PORTAL_HOST_IP}'","hostnames":["'${PORTAL_HOST_DOMAIN}'","vault.'${PORTAL_HOST_DOMAIN}'","harbor.'${PORTAL_HOST_DOMAIN}'","portal.'${PORTAL_HOST_DOMAIN}'","keycloak.'${PORTAL_HOST_DOMAIN}'"]},{"ip":"'${CLUSTER_ENDPOINT}'","hostnames":["'${PORTAL_MASTER_NODE_PUBLIC_IP}'"]}]}}}}' 2>/dev/null || true

# ============================================================
# Fix cp-catalog-api: Mount config.env file
# Go application expects config.env at root, but it's only in ConfigMap
# ============================================================
echo ">>> Mounting config.env for cp-catalog-api..."
kubectl patch deployment cp-catalog-api-deployment -n cp-portal --type=strategic -p '
{
  "spec": {
    "template": {
      "spec": {
        "volumes": [
          {
            "name": "config-volume",
            "configMap": {
              "name": "cp-portal-catalog-config"
            }
          }
        ],
        "containers": [{
          "name": "cp-catalog-api",
          "volumeMounts": [
            {"name": "config-volume", "mountPath": "/config.env", "subPath": "config.env"}
          ]
        }]
      }
    }
  }
}' 2>/dev/null || echo ">>> cp-catalog-api config mount may already exist, skipping..."

# ============================================================
# Fix cp-migration-ui: Add SSL truststore for self-signed certificate
# Java apps need the k-paas.io CA in their truststore
# ============================================================
echo ">>> Adding SSL truststore to cp-migration-ui..."
kubectl patch deployment cp-migration-ui-deployment -n cp-portal --type=strategic -p '
{
  "spec": {
    "template": {
      "spec": {
        "volumes": [
          {"name": "k-paas-certs", "secret": {"secretName": "k-paas.io-tls"}},
          {"name": "shared-truststore", "emptyDir": {}}
        ],
        "initContainers": [{
          "name": "import-certs",
          "image": "eclipse-temurin:17-jre",
          "command": ["sh", "-c"],
          "args": ["cp $JAVA_HOME/lib/security/cacerts /tmp/truststore.jks && keytool -import -trustcacerts -keystore /tmp/truststore.jks -storepass changeit -noprompt -alias k-paas-ca -file /certs/tls.crt && cp /tmp/truststore.jks /shared/truststore.jks"],
          "volumeMounts": [
            {"name": "k-paas-certs", "mountPath": "/certs"},
            {"name": "shared-truststore", "mountPath": "/shared"}
          ],
          "securityContext": {"runAsUser": 1000, "runAsNonRoot": true, "allowPrivilegeEscalation": false}
        }],
        "containers": [{
          "name": "cp-migration-ui",
          "volumeMounts": [{"name": "shared-truststore", "mountPath": "/truststore"}],
          "env": [{"name": "JAVA_TOOL_OPTIONS", "value": "-Djavax.net.ssl.trustStore=/truststore/truststore.jks -Djavax.net.ssl.trustStorePassword=changeit"}]
        }]
      }
    }
  }
}' 2>/dev/null || echo ">>> cp-migration-ui SSL truststore may already exist, skipping..."

# ============================================================
# Add logs volume for common-api (FileNotFoundException: /home/1000/logs/spring.log)
# Helm template only supports PVC, so we need to patch with emptyDir after deployment
# ============================================================
echo ">>> Adding logs volume for cp-portal-common-api..."
kubectl patch deployment cp-portal-common-api-deployment -n cp-portal --type "json" -p '[
    {"op":"add","path":"/spec/template/spec/volumes","value":[{"name":"logs","emptyDir":{}}]},
    {"op":"add","path":"/spec/template/spec/containers/0/volumeMounts","value":[{"name":"logs","mountPath":"/home/1000/logs"}]}
]' 2>/dev/null || echo ">>> logs volume may already exist, skipping..."

# ============================================================
# ARM64: imagePullPolicy는 Already set to Always in ghcr.io 설정에서 처리됨
# ghcr.io/dasomel-k-pass에서 이미지를 pull하도록 Always로 설정
# ============================================================
# (ghcr.io 이미지 사용으로 인해 imagePullPolicy: Never 설정 제거됨)

# ============================================================
# Wait for Keycloak to be ready and restart cp-portal-ui
# cp-portal-ui requires Keycloak OIDC issuer to be accessible at startup
# ============================================================
echo ">>> Waiting for Keycloak to be ready..."
kubectl rollout status statefulset/keycloak -n keycloak --timeout=300s 2>/dev/null || echo "Warning: Keycloak rollout status check failed"

# Wait for Keycloak OIDC endpoint to be accessible
echo ">>> Checking Keycloak OIDC endpoint..."
KEYCLOAK_URL="https://keycloak.${PORTAL_HOST_DOMAIN}/realms/cp-realm/.well-known/openid-configuration"
for i in {1..30}; do
    if curl -sk "$KEYCLOAK_URL" | grep -q "issuer"; then
        echo ">>> Keycloak OIDC endpoint is ready"
        break
    fi
    echo ">>> Waiting for Keycloak OIDC endpoint... ($i/30)"
    sleep 10
done

# ============================================================
# NOTE: Helm values already contain correct service DNS names
# DO NOT overwrite ConfigMap with ClusterIP - it breaks when pods restart
# The Helm chart sets proper values like:
#   CP_PORTAL_METRIC_COLLECTOR_API_URI: http://cp-metrics-api-service.cp-portal.svc.cluster.local:8900
#   VAULT_URL: http://openbao.openbao.svc.cluster.local:8200
# ============================================================
echo ">>> Skipping ConfigMap patch - Helm values already correct"

# ============================================================
# Fix Mixed Content Error: Browser needs HTTPS URLs for API calls
# When portal is accessed via HTTPS, browser blocks HTTP API requests
# Change browser-facing URIs to use HTTPS ingress paths
# ============================================================
echo ">>> Patching cp-portal-configmap with HTTPS ingress URLs for browser..."
PORTAL_HTTPS_HOST="https://portal.${PORTAL_HOST_DOMAIN}"

kubectl patch configmap cp-portal-configmap -n cp-portal --type=merge -p "{
  \"data\": {
    \"CP_PORTAL_API_URI\": \"${PORTAL_HTTPS_HOST}/cpapi\",
    \"CP_PORTAL_CATALOG_API_URI\": \"${PORTAL_HTTPS_HOST}/cpcatalog\",
    \"CP_PORTAL_CHAOS_API_URI\": \"${PORTAL_HTTPS_HOST}/cpchaos\",
    \"CP_PORTAL_REMOTE_API_URI\": \"${PORTAL_HTTPS_HOST}/cpremote\",
    \"CP_MIGRATION_API_URI\": \"${PORTAL_HTTPS_HOST}/cpmig\",
    \"CP_MIGRATION_AUTH_URI\": \"${PORTAL_HTTPS_HOST}/cpmigauth\"
  }
}" || echo "Warning: Failed to patch cp-portal-configmap with HTTPS URLs"

echo ">>> cp-portal-configmap patched with HTTPS ingress URLs"

# ============================================================
# Fix Keycloak DB URL: Use MariaDB service DNS name for stability
# ============================================================
echo ">>> Patching Keycloak StatefulSet with MariaDB service DNS..."
kubectl set env statefulset/keycloak -n keycloak KC_DB_URL="jdbc:mariadb://mariadb.mariadb:3306/keycloak" 2>/dev/null || echo "Warning: Failed to set Keycloak DB URL"

# ============================================================
# ARM64: Fix migration-ui probe configuration
# migration-ui uses port 8097 with context path /cpmigui
# ============================================================
if [ "$(uname -m)" = "aarch64" ]; then
    echo ">>> Fixing cp-portal-migration-ui probe configuration..."
    kubectl patch deployment cp-portal-migration-ui-deployment -n cp-portal --type='json' -p='[
      {"op": "replace", "path": "/spec/template/spec/containers/0/ports/0/containerPort", "value": 8097},
      {"op": "replace", "path": "/spec/template/spec/containers/0/livenessProbe/httpGet/port", "value": 8097},
      {"op": "replace", "path": "/spec/template/spec/containers/0/livenessProbe/httpGet/path", "value": "/cpmigui/actuator/health/liveness"},
      {"op": "replace", "path": "/spec/template/spec/containers/0/readinessProbe/httpGet/port", "value": 8097},
      {"op": "replace", "path": "/spec/template/spec/containers/0/readinessProbe/httpGet/path", "value": "/cpmigui/actuator/health/readiness"}
    ]' 2>/dev/null || echo "Warning: migration-ui probe patch may have failed"
fi

# ============================================================
# ARM64: Create catalog-api config.env ConfigMap
# Go application expects config.env file at root directory
# ============================================================
if [ "$(uname -m)" = "aarch64" ]; then
    echo ">>> Creating catalog-api config.env ConfigMap..."

    # Get OpenBao credentials from secret
    VAULT_ROLE_NAME=$(kubectl get secret cp-portal-secret -n cp-portal -o jsonpath='{.data.VAULT_ROLE_NAME}' 2>/dev/null | base64 -d || echo "cp-secret-manager-role")
    VAULT_ROLE_ID=$(kubectl get secret cp-portal-secret -n cp-portal -o jsonpath='{.data.VAULT_ROLE_ID}' 2>/dev/null | base64 -d || echo "")
    VAULT_SECRET_ID=$(kubectl get secret cp-portal-secret -n cp-portal -o jsonpath='{.data.VAULT_SECRET_ID}' 2>/dev/null | base64 -d || echo "")
    # Use service DNS name instead of IP for stability
    OPENBAO_URL="http://openbao.openbao:8200"

    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: cp-portal-catalog-config
  namespace: cp-portal
data:
  config.env: |
    SERVER_PORT=:8093
    JWT_SECRET=dfa4ad2646d6b4864f2dfa5428249d4eb54dc29bf3f29658fd4676d25706f83c9fc4ef626fa60d2c589a79ebec448ba4d591e2fcb04926fab783fcae50e97c06
    HELM_REPO_CONFIG=/home/1000/helm/repositories.yaml
    HELM_REPO_CACHE=/home/1000/helm/cache
    HELM_REPO_CA=/home/1000/helm/cert
    VAULT_URL=${OPENBAO_URL}
    VAULT_ROLE_NAME=${VAULT_ROLE_NAME}
    VAULT_ROLE_ID=${VAULT_ROLE_ID}
    VAULT_SECRET_ID=${VAULT_SECRET_ID}
    VAULT_CLUSTER_PATH=secret/data/cluster
    VAULT_USER_PATH=secret/data/user
    ARTIFACT_HUB_API_URL=https://artifacthub.io/api/v1
    ARTIFACT_HUB_REPO_SEARCH=/repositories/search?kind=0
    ARTIFACT_HUB_PACKAGE_SEARCH=/packages/search?kind=0&sort=relevance&deprecated=true
    ARTIFACT_HUB_PACKAGE_DETAIL=/packages/helm/{repoName}/{packageName}
    ARTIFACT_HUB_PACKAGE_VALUES=/packages/{packageID}/{version}/values
    ARTIFACT_HUB_PACKAGE_LOGO_URL=https://artifacthub.io/image/
EOF

    echo ">>> Patching catalog-api deployment to mount config.env..."
    kubectl patch deployment cp-portal-catalog-api-deployment -n cp-portal --type='json' -p='[
      {"op": "add", "path": "/spec/template/spec/volumes/-", "value": {"name": "catalog-config", "configMap": {"name": "cp-portal-catalog-config"}}},
      {"op": "add", "path": "/spec/template/spec/containers/0/volumeMounts/-", "value": {"name": "catalog-config", "mountPath": "/config.env", "subPath": "config.env"}}
    ]' 2>/dev/null || echo "Warning: catalog-api config mount patch may have failed"
fi

# ============================================================
# Fix CoreDNS: Add k-paas.io hosts for internal DNS resolution
# Pods need to resolve k-paas.io, keycloak.k-paas.io etc to Ingress IP
# ============================================================
echo ">>> Configuring CoreDNS with k-paas.io hosts..."
INGRESS_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "192.168.100.201")

kubectl patch configmap coredns -n kube-system --type=merge -p "{
  \"data\": {
    \"Corefile\": \".:53 {\n    errors\n    health {\n        lameduck 5s\n    }\n    ready\n    hosts {\n      ${INGRESS_IP} k-paas.io keycloak.k-paas.io portal.k-paas.io harbor.k-paas.io openbao.k-paas.io chartmuseum.k-paas.io\n      fallthrough\n    }\n    kubernetes cluster.local in-addr.arpa ip6.arpa {\n      pods insecure\n      fallthrough in-addr.arpa ip6.arpa\n    }\n    prometheus :9153\n    forward . /etc/resolv.conf {\n      prefer_udp\n      max_concurrent 1000\n    }\n    cache 30\n    loop\n    reload\n    loadbalance\n}\n\"
  }
}" 2>/dev/null || echo "Warning: CoreDNS patch may have failed"

kubectl rollout restart deployment coredns -n kube-system 2>/dev/null || true
echo ">>> CoreDNS configured with k-paas.io hosts"

# ============================================================
# Fix DNS: Bypass nodelocaldns for cp-portal pods
# nodelocaldns caches DNS and doesn't pick up CoreDNS hosts changes
# Set dnsPolicy to None and point directly to CoreDNS
# ============================================================
echo ">>> Configuring DNS policy for cp-portal deployments..."
COREDNS_IP=$(kubectl get svc -n kube-system coredns -o jsonpath='{.spec.clusterIP}' 2>/dev/null || kubectl get svc -n kube-system kube-dns -o jsonpath='{.spec.clusterIP}' 2>/dev/null || echo "10.233.0.3")

DNS_PATCH="{
  \"spec\": {
    \"template\": {
      \"spec\": {
        \"dnsPolicy\": \"None\",
        \"dnsConfig\": {
          \"nameservers\": [\"${COREDNS_IP}\"],
          \"searches\": [\"cp-portal.svc.cluster.local\", \"svc.cluster.local\", \"cluster.local\"],
          \"options\": [{\"name\": \"ndots\", \"value\": \"5\"}]
        }
      }
    }
  }
}"

for deploy in cp-portal-ui-deployment cp-portal-common-api-deployment cp-portal-migration-ui-deployment cp-portal-catalog-api-deployment; do
    kubectl patch deployment $deploy -n cp-portal --type=strategic -p "$DNS_PATCH" 2>/dev/null || echo "Warning: DNS patch for $deploy may have failed"
done
echo ">>> DNS policy configured for cp-portal deployments"

# ============================================================
# Fix SSL: Add init container to import k-paas.io certificate
# Java apps need the self-signed cert in their truststore
# Uses shared emptyDir volume to pass truststore from init to main container
# ============================================================
echo ">>> Configuring SSL truststore for Java-based cp-portal deployments..."

SSL_PATCH='{
  "spec": {
    "template": {
      "spec": {
        "initContainers": [{
          "name": "import-certs",
          "image": "eclipse-temurin:17-jre",
          "command": ["sh", "-c"],
          "args": ["cp $JAVA_HOME/lib/security/cacerts /tmp/truststore.jks && keytool -import -trustcacerts -keystore /tmp/truststore.jks -storepass changeit -noprompt -alias k-paas-ca -file /certs/tls.crt && cp /tmp/truststore.jks /shared/truststore.jks"],
          "securityContext": {
            "allowPrivilegeEscalation": false,
            "runAsNonRoot": true,
            "runAsUser": 1000,
            "capabilities": {"drop": ["ALL"]},
            "seccompProfile": {"type": "RuntimeDefault"}
          },
          "volumeMounts": [
            {"name": "k-paas-certs", "mountPath": "/certs"},
            {"name": "shared-truststore", "mountPath": "/shared"}
          ]
        }],
        "volumes": [
          {"name": "k-paas-certs", "secret": {"secretName": "k-paas.io-tls"}},
          {"name": "shared-truststore", "emptyDir": {}}
        ]
      }
    }
  }
}'

# Apply SSL patch to Java-based deployments
for deploy in cp-portal-ui-deployment cp-portal-common-api-deployment cp-portal-migration-ui-deployment; do
    kubectl patch deployment $deploy -n cp-portal --type=strategic -p "$SSL_PATCH" 2>/dev/null || echo "Warning: SSL patch for $deploy may have failed"
done

# Add JAVA_TOOL_OPTIONS and truststore mount to containers
for deploy in cp-portal-ui-deployment cp-portal-common-api-deployment cp-portal-migration-ui-deployment; do
    CONTAINER_NAME=$(echo $deploy | sed 's/-deployment//' | sed 's/cp-portal-/cp-/')
    kubectl patch deployment $deploy -n cp-portal --type=strategic -p "{
      \"spec\": {
        \"template\": {
          \"spec\": {
            \"containers\": [{
              \"name\": \"${CONTAINER_NAME}\",
              \"env\": [{\"name\": \"JAVA_TOOL_OPTIONS\", \"value\": \"-Djavax.net.ssl.trustStore=/truststore/truststore.jks -Djavax.net.ssl.trustStorePassword=changeit\"}],
              \"volumeMounts\": [{\"name\": \"shared-truststore\", \"mountPath\": \"/truststore\"}]
            }]
          }
        }
      }
    }" 2>/dev/null || echo "Warning: JAVA_TOOL_OPTIONS patch for $deploy may have failed"
done
echo ">>> SSL truststore configured for Java-based deployments"

# Restart cp-portal-ui and cp-portal-migration-ui to pick up all changes
echo ">>> Restarting all cp-portal deployments..."
kubectl rollout restart deployment -n cp-portal
kubectl rollout status deployment/cp-portal-ui-deployment -n cp-portal --timeout=300s 2>/dev/null || echo "Warning: cp-portal-ui rollout may still be in progress"

echo "========== 06.install_k-pass Portal END =========="
