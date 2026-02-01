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

# Download v1.7.0 Deployment file and check file path
if [ ! -f "cp-portal-deployment-v1.7.0.tar.gz" ]; then
    echo "Downloading CP Portal deployment files..."
    wget --content-disposition https://nextcloud.k-paas.org/index.php/s/qrApL4sP5eC2WMX/download
    tar -xvf cp-portal-deployment-v1.7.0.tar.gz
else
    echo "CP Portal deployment files already downloaded"
fi

# [Fix] Make namespace creation idempotent in all scripts
echo "Patching scripts to handle existing namespaces..."
find "$INSTALL_PATH"/workspace/container-platform -name "*.sh" -type f -print0 | xargs -0 sed -i 's/kubectl create ns \([^ ]*\)/kubectl create ns \1 2>\/dev\/null || true/g'

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
EOF

sudo systemctl restart crio || true

# Wait for API server to be ready after CRI-O restart
echo "Waiting for Kubernetes API server to be ready..."
for i in {1..30}; do
    if kubectl get nodes &> /dev/null; then
        echo "API server is ready"
        break
    fi
    echo "Waiting for API server... ($i/30)"
    sleep 10
done

# Fix /etc/hosts with correct LoadBalancer IP on ALL nodes
echo "Updating /etc/hosts with correct LoadBalancer IP on all nodes..."
INGRESS_LB_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
if [ -n "$INGRESS_LB_IP" ]; then
    echo "Found LoadBalancer IP: $INGRESS_LB_IP"

    # Hosts entries to add
    HOSTS_ENTRIES="$INGRESS_LB_IP $PORTAL_HOST_DOMAIN openbao.$PORTAL_HOST_DOMAIN harbor.$PORTAL_HOST_DOMAIN keycloak.$PORTAL_HOST_DOMAIN portal.$PORTAL_HOST_DOMAIN chartmuseum.$PORTAL_HOST_DOMAIN"

    # Update on local node (master01)
    sudo sed -i "/$PORTAL_HOST_DOMAIN/d" /etc/hosts
    echo "$HOSTS_ENTRIES" | sudo tee -a /etc/hosts

    # Update on all other nodes via SSH
    ALL_NODES="$MASTER02 $MASTER03 $WORKER01 $WORKER02 $WORKER03"
    for node in $ALL_NODES; do
        echo "Updating /etc/hosts on $node..."
        ssh -o StrictHostKeyChecking=no ubuntu@$node "sudo sed -i '/$PORTAL_HOST_DOMAIN/d' /etc/hosts && echo '$HOSTS_ENTRIES' | sudo tee -a /etc/hosts" 2>/dev/null || echo "Warning: Could not update /etc/hosts on $node"
    done
    echo "All nodes updated with /etc/hosts entries"
else
    echo "Warning: Could not get LoadBalancer IP, /etc/hosts may need manual update"
fi

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
    script: echo "$CA_CERT" > /usr/local/share/ca-certificates/{HOST_DOMAIN}.crt && update-ca-certificates && for cr in crio containerd; do if systemctl list-unit-files --type=service | grep -q "^$${cr}.service"; then systemctl restart "$cr"; fi; done
EOF

# Execute the Container Platform Portal deployment script
echo "========== Deploying CP Portal =========="
cd "$INSTALL_PATH/workspace/container-platform/cp-portal-deployment/script" || exit
chmod +x deploy-cp-portal.sh
./deploy-cp-portal.sh > deploy-portal-result.log 2>&1

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

            if [ $${#KEY_ARR[@]} -ge 2 ]; then
                # Save keys to Kubernetes secret
                kubectl create secret generic openbao-unseal-keys -n openbao \
                    --from-literal=unseal_key_1="$${KEY_ARR[0]}" \
                    --from-literal=unseal_key_2="$${KEY_ARR[1]}" \
                    --from-literal=unseal_key_3="$${KEY_ARR[2]:-}" 2>/dev/null || true

                # Unseal OpenBao
                kubectl exec openbao-0 -n openbao -- bao operator unseal "$${KEY_ARR[0]}" 2>/dev/null || true
                kubectl exec openbao-0 -n openbao -- bao operator unseal "$${KEY_ARR[1]}" 2>/dev/null || true

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

            if [ $${#KEY_ARR[@]} -ge 2 ]; then
                kubectl create secret generic openbao-unseal-keys -n openbao \
                    --from-literal=unseal_key_1="$${KEY_ARR[0]}" \
                    --from-literal=unseal_key_2="$${KEY_ARR[1]}" \
                    --from-literal=unseal_key_3="$${KEY_ARR[2]:-}" 2>/dev/null || true
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
    export BAO_ADDR="http://$${OPENBAO_IP}:8200"
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

# Fix: Delete cp-cert-setup DaemonSet if it exists (it tries to restart containerd which doesn't exist in CRI-O environment)
echo "Checking for cp-cert-setup DaemonSet..."
if kubectl get daemonset cp-cert-setup-daemonset -n kube-system &> /dev/null; then
    echo "Deleting cp-cert-setup DaemonSet (incompatible with CRI-O)..."
    kubectl delete daemonset cp-cert-setup-daemonset -n kube-system || true
    echo "cp-cert-setup DaemonSet deleted"
fi

# Fix: Create harbor.k-paas.io-tls secret for Harbor core component
echo "Creating harbor.k-paas.io-tls secret for Harbor..."
kubectl get secret k-paas.io-tls -n harbor -o yaml 2>/dev/null | \
  sed 's/name: k-paas.io-tls/name: harbor.k-paas.io-tls/' | \
  kubectl apply -f - 2>/dev/null || echo "Harbor TLS secret already exists or Harbor not deployed"

# ============================================================
# Adding entries to Pod /etc/hosts with HostAliases
# NOTE: Deployment names use 'cp-portal-*' for API/UI, standard names for others
# ============================================================
echo "Adding entries to Pod /etc/hosts with HostAliases"

# Define hostAliases JSON patch (reusable)
HOSTALIAS_PATCH='{"spec":{"template":{"spec":{"hostAliases":[{"ip":"'${PORTAL_HOST_IP}'","hostnames":["'${PORTAL_HOST_DOMAIN}'","vault.'${PORTAL_HOST_DOMAIN}'","harbor.'${PORTAL_HOST_DOMAIN}'","portal.'${PORTAL_HOST_DOMAIN}'","keycloak.'${PORTAL_HOST_DOMAIN}'","openbao.'${PORTAL_HOST_DOMAIN}'","chartmuseum.'${PORTAL_HOST_DOMAIN}'"]},{"ip":"'${CLUSTER_ENDPOINT}'","hostnames":["'${PORTAL_MASTER_NODE_PUBLIC_IP}'"]}]}}}}'

# Patch all deployments with hostAliases (AMD64 uses cp-portal-* naming)
for dep in \
    cp-portal-terraman-deployment \
    cp-portal-metric-api-deployment \
    cp-portal-common-api-deployment \
    cp-portal-api-deployment \
    cp-portal-ui-deployment \
    cp-portal-catalog-api-deployment \
    cp-portal-chaos-api-deployment \
    cp-portal-chaos-collector-deployment \
    cp-portal-migration-api-deployment \
    cp-portal-migration-auth-deployment \
    cp-portal-migration-ui-deployment \
    cp-portal-remote-api-deployment
do
    echo ">>> Patching hostAliases for $${dep}..."
    kubectl patch deployment $${dep} -n cp-portal --type "merge" -p "$${HOSTALIAS_PATCH}" 2>/dev/null || echo ">>> Skipped $${dep} (may not exist)"
done

# Keycloak uses Deployment (not StatefulSet) in AMD64 standard installation
kubectl patch deployment cp-keycloak -n keycloak --type "merge" \
    -p '{"spec":{"template":{"spec":{"hostAliases":[{"ip":"'${PORTAL_HOST_IP}'","hostnames":["'${PORTAL_HOST_DOMAIN}'","vault.'${PORTAL_HOST_DOMAIN}'","harbor.'${PORTAL_HOST_DOMAIN}'","portal.'${PORTAL_HOST_DOMAIN}'","keycloak.'${PORTAL_HOST_DOMAIN}'"]},{"ip":"'${CLUSTER_ENDPOINT}'","hostnames":["'${PORTAL_MASTER_NODE_PUBLIC_IP}'"]}]}}}}' 2>/dev/null || true

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
# Wait for Keycloak to be ready and restart cp-portal-ui
# cp-portal-ui requires Keycloak OIDC issuer to be accessible at startup
# ============================================================
echo ">>> Waiting for Keycloak to be ready..."
kubectl rollout status deployment/cp-keycloak -n keycloak --timeout=300s 2>/dev/null || echo "Warning: Keycloak rollout status check failed"

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
# Fix CoreDNS: Add k-paas.io hosts for internal DNS resolution
# Pods need to resolve k-paas.io, keycloak.k-paas.io etc to Ingress IP
# ============================================================
echo ">>> Configuring CoreDNS with k-paas.io hosts..."
INGRESS_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "${PORTAL_HOST_IP}")

kubectl patch configmap coredns -n kube-system --type=merge -p "{
  \"data\": {
    \"Corefile\": \".:53 {\n    errors\n    health {\n        lameduck 5s\n    }\n    ready\n    hosts {\n      $${INGRESS_IP} ${PORTAL_HOST_DOMAIN} keycloak.${PORTAL_HOST_DOMAIN} portal.${PORTAL_HOST_DOMAIN} harbor.${PORTAL_HOST_DOMAIN} openbao.${PORTAL_HOST_DOMAIN} chartmuseum.${PORTAL_HOST_DOMAIN}\n      fallthrough\n    }\n    kubernetes cluster.local in-addr.arpa ip6.arpa {\n      pods insecure\n      fallthrough in-addr.arpa ip6.arpa\n    }\n    prometheus :9153\n    forward . /etc/resolv.conf {\n      prefer_udp\n      max_concurrent 1000\n    }\n    cache 30\n    loop\n    reload\n    loadbalance\n}\n\"
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
          \"nameservers\": [\"$${COREDNS_IP}\"],
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
    CONTAINER_NAME=$(echo $deploy | sed 's/-deployment//')
    kubectl patch deployment $deploy -n cp-portal --type=strategic -p "{
      \"spec\": {
        \"template\": {
          \"spec\": {
            \"containers\": [{
              \"name\": \"$${CONTAINER_NAME}\",
              \"env\": [{\"name\": \"JAVA_TOOL_OPTIONS\", \"value\": \"-Djavax.net.ssl.trustStore=/truststore/truststore.jks -Djavax.net.ssl.trustStorePassword=changeit\"}],
              \"volumeMounts\": [{\"name\": \"shared-truststore\", \"mountPath\": \"/truststore\"}]
            }]
          }
        }
      }
    }" 2>/dev/null || echo "Warning: JAVA_TOOL_OPTIONS patch for $deploy may have failed"
done
echo ">>> SSL truststore configured for Java-based deployments"

# ============================================================
# NOTE: Helm values already contain correct service DNS names
# DO NOT overwrite ConfigMap with ClusterIP - it breaks when pods restart
# The Helm chart sets proper values like:
#   CP_PORTAL_METRIC_COLLECTOR_API_URI: http://cp-portal-metric-api-service.cp-portal.svc.cluster.local:8900
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
    \"CP_PORTAL_API_URI\": \"$${PORTAL_HTTPS_HOST}/cpapi\",
    \"CP_PORTAL_CATALOG_API_URI\": \"$${PORTAL_HTTPS_HOST}/cpcatalog\",
    \"CP_PORTAL_CHAOS_API_URI\": \"$${PORTAL_HTTPS_HOST}/cpchaos\",
    \"CP_PORTAL_REMOTE_API_URI\": \"$${PORTAL_HTTPS_HOST}/cpremote\",
    \"CP_MIGRATION_API_URI\": \"$${PORTAL_HTTPS_HOST}/cpmig\",
    \"CP_MIGRATION_AUTH_URI\": \"$${PORTAL_HTTPS_HOST}/cpmigauth\"
  }
}" || echo "Warning: Failed to patch cp-portal-configmap with HTTPS URLs"

echo ">>> cp-portal-configmap patched with HTTPS ingress URLs"

# ============================================================
# Fix Keycloak DB URL: Use MariaDB service DNS name for stability
# ============================================================
echo ">>> Patching Keycloak Deployment with MariaDB service DNS..."
kubectl set env deployment/cp-keycloak -n keycloak KC_DB_URL="jdbc:mariadb://mariadb.mariadb:3306/keycloak" 2>/dev/null || echo "Warning: Failed to set Keycloak DB URL"

# Restart cp-portal-ui and cp-portal-migration-ui to pick up all changes
echo ">>> Restarting all cp-portal deployments..."
kubectl rollout restart deployment -n cp-portal
kubectl rollout status deployment/cp-portal-ui-deployment -n cp-portal --timeout=300s 2>/dev/null || echo "Warning: cp-portal-ui rollout may still be in progress"

echo "========== 06.master_install_k-pass_portal COMPLETED =========="
echo ""
echo "Portal Access Information:"
echo "  Portal URL: https://portal.${PORTAL_HOST_DOMAIN}"
echo "  Harbor URL: https://harbor.${PORTAL_HOST_DOMAIN}"
echo "  Keycloak URL: https://keycloak.${PORTAL_HOST_DOMAIN}"
echo ""
echo "Please make sure to add the following to your /etc/hosts:"
echo "  ${PORTAL_HOST_IP} ${PORTAL_HOST_DOMAIN} harbor.${PORTAL_HOST_DOMAIN} keycloak.${PORTAL_HOST_DOMAIN} portal.${PORTAL_HOST_DOMAIN}"
echo ""
