#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status.
set -e

# ==============================================================================
# Configuration
# ==============================================================================
# --- Harbor Configuration ---
HARBOR_URL="harbor.k-paas.io"
HARBOR_USER="admin"
HARBOR_PASSWORD="Harbor12345" # Consider using environment variables for credentials

# --- Kubernetes Configuration ---
K8S_NAMESPACE="egovframe"

# --- Application Configuration ---
APP_NAME="egovframe-web-sample"
APP_VERSION="4.3.0"
DOCKER_IMAGE="${HARBOR_URL}/${K8S_NAMESPACE}/${APP_NAME}:${APP_VERSION}"
REGISTRY_SECRET_NAME="egovregistrykey"

# ==============================================================================
# Script Execution
# ==============================================================================

echo "### 1. Registering CA Certificate..."
sudo cp /home/ubuntu/workspace/container-platform/cp-portal-deployment/certs/ca.crt /usr/local/share/ca-certificates/
sudo update-ca-certificates

echo "### 2. Creating Kubernetes Namespace..."
# Ignore error if namespace already exists
kubectl create namespace "${K8S_NAMESPACE}" || true

echo "### 3. Creating Harbor Project..."
# Ignore error if project already exists
curl -u "${HARBOR_USER}:${HARBOR_PASSWORD}" -X POST "https://${HARBOR_URL}/api/v2.0/projects" \
-H "Content-Type: application/json" -k \
-d "{\"project_name\": \"${K8S_NAMESPACE}\", \"private\": true}" || true

echo "### 4. Building Container Image..."
sudo podman build . -t "${DOCKER_IMAGE}"

echo "### 5. Logging into Harbor..."
sudo podman login "${HARBOR_URL}" -u "${HARBOR_USER}" -p "${HARBOR_PASSWORD}" --tls-verify=false

echo "### 6. Pushing Image to Harbor..."
sudo podman push --tls-verify=false "${DOCKER_IMAGE}"

echo "### 7. Creating Docker Registry Secret for Kubernetes..."
# Delete the secret if it exists and recreate it
kubectl delete secret "${REGISTRY_SECRET_NAME}" --namespace="${K8S_NAMESPACE}" --ignore-not-found
kubectl create secret docker-registry "${REGISTRY_SECRET_NAME}" \
  --namespace="${K8S_NAMESPACE}" \
  --docker-server="${HARBOR_URL}" \
  --docker-username="${HARBOR_USER}" \
  --docker-password="${HARBOR_PASSWORD}"

echo "### 8. Deploying Egovframe Sample Web Application to K-PaaS..."
kubectl apply -f ./k8s/deployment.yaml --namespace="${K8S_NAMESPACE}"
kubectl apply -f ./k8s/service.yaml --namespace="${K8S_NAMESPACE}"
kubectl apply -f ./k8s/ingress.yaml --namespace="${K8S_NAMESPACE}"

echo "### Deployment finished successfully! ###"
