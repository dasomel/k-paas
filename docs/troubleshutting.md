# TroubleShutting

## 01. Harbor

### container image upload failed
> Failed to pull image "harbor.k-paas.io/cp-portal-repository/cp-portal-xxx:latest": reading manifest latest in harbor.k-paas.io/cp-portal-repository/cp-portal-xxx: unknown: repository cp-portal-repository/cp-portal-xxx not found
> Error: INSTALLATION FAILED: failed to fetch https://harbor.k-paas.io/chartrepo/cp-portal-repository/charts/cp-portal-app-1.5.0.tgz : 502 Bad Gateway

```shell
source ~/workspace/container-platform/cp-portal-deployment/script/cp-portal-vars.sh
sudo podman login harbor.k-paas.io --username $REPOSITORY_USERNAME --password $REPOSITORY_PASSWORD

sudo podman push harbor.k-paas.io/cp-portal-repository/cp-keycloak:latest
sudo podman push harbor.k-paas.io/cp-portal-repository/cp-portal-ui:latest
sudo podman push harbor.k-paas.io/cp-portal-repository/cp-portal-api:latest
sudo podman push harbor.k-paas.io/cp-portal-repository/cp-portal-common-api:latest
sudo podman push harbor.k-paas.io/cp-portal-repository/cp-portal-metric-api:latest
sudo podman push harbor.k-paas.io/cp-portal-repository/cp-portal-terraman:latest

cd ~/workspace/container-platform/cp-portal-deployment/script
# [] Check the status of cp-portal-terraman pod..

helm install -f ../values/cp-portal-ui.yaml         cp-portal-ui          cp-portal-repository/cp-portal-app -n cp-portal
helm install -f ../values/cp-portal-api.yaml        cp-portal-api         cp-portal-repository/cp-portal-app -n cp-portal
helm install -f ../values/cp-portal-common-api.yaml cp-portal-common-api  cp-portal-repository/cp-portal-app -n cp-portal
helm install -f ../values/cp-portal-metric-api.yaml cp-portal-metric-api  cp-portal-repository/cp-portal-app -n cp-portal
helm install -f ../values/cp-portal-terraman.yaml   cp-portal-terraman    cp-portal-repository/cp-portal-app -n cp-portal
```

### harbor databasae restart
```shell
kubectl patch statefulset cp-harbor-database -n harbor --type='json' -p='[{"op": "remove", "path": "/spec/template/spec/containers/volumeMounts", "value": {"name": "shm-volume" } }]'
```

## 02. VM(Virtualbox)

### Network connection Error
> Failed to create pod sandbox: rpc error: code = Unknown desc = failed to create pod network sandbox k8s_cp-keycloak-649956796c-wfkzz_keycloak_16dcbd24-4d28-4002-9e08-181add6aa362_0(e2c5bbaca6dfb5abc3e4ccf4266dd088ba57246b0438ec19bfdb4a7a308ff74f): error adding pod keycloak_cp-keycloak-649956796c-wfkzz to CNI network "k8s-pod-network": plugin type="calico" failed (add): error getting ClusterInformation: connection is unauthorized: Unauthorized

```shell
vagrant reload
```

### Network port error
> [FATAL] plugin/loop: Loop (169.254.25.10:35015 -> 169.254.25.10:53) detected for zone ".", see https://coredns.io/plugins/loop#troubleshooting. Query: "HINFO 8451044921545237505.3341538791464836430."

```shell
# kube-apiserver bind-address change
LOCAL_IP=$(hostname -i | awk '{print $3}')
sudo sed -i 's/bind-address=0.0.0.0/bind-address='"$LOCAL_IP"'/g' /etc/kubernetes/manifests/kube-apiserver.yaml

sudo systemctl restart keepalived
sudo systemctl restart haproxy

sudo systemctl restart kubelet
sudo systemctl restart crio

# status
journalctl -xfeu kubelet
```

## 03. Vault

### Unseal Vault
| NAME       | READY | STATUS  |
|------------|-------|---------|
| cp-vault-0 | 0/1   | Running |
> Pod(vault) not ready after restart
 
```shell
source /vagrant/scripts/00.global_variable.sh
source ~/workspace/container-platform/cp-portal-deployment/script/cp-portal-vars.sh
CURL_CMD="curl --silent --show-error -k"

# node restart or pod(vault) restart
${CURL_CMD} --output /dev/null \
    -X POST \
    -d '{"key":'"\"$(sed 's/"/ " /g' ~/workspace/container-platform/cp-portal-deployment/vault/cp-vault-unseal-key | awk '{ print $6 }')\""'}' \
    "${VAULT_URL}/v1/sys/unseal"

${CURL_CMD} --output /dev/null \
    -X POST \
    -d '{"key":'"\"$(sed 's/"/ " /g' ~/workspace/container-platform/cp-portal-deployment/vault/cp-vault-unseal-key | awk '{ print $10 }')\""'}' \
    "${VAULT_URL}/v1/sys/unseal"
```
