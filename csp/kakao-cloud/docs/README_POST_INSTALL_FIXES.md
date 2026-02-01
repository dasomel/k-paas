해당 # K-PaaS Post-Installation Fix Scripts

This directory contains scripts for fixing common issues after K-PaaS deployment on Kakao Cloud.

## Overview

After deploying K-PaaS cluster, several post-installation fixes are required:
1. Harbor certificate configuration for CRI-O
2. DNS resolution for k-paas.io domains in pods
3. API server certificate regeneration for external access

## Scripts

### 07.fix_harbor_certificate.sh
**Purpose**: Configures Harbor's self-signed TLS certificate on all worker nodes

**What it does**:
- Downloads Harbor certificate from master-1
- Installs certificate to system CA trust store on all workers
- Configures CRI-O to trust Harbor registry
- Restarts CRI-O service

**When to use**: When worker nodes cannot pull images from Harbor due to certificate errors

**Usage**:
```bash
cd /home/ubuntu/scripts
bash 07.fix_harbor_certificate.sh
```

---

### 08.fix_coredns_hostaliases.sh
**Purpose**: Fixes DNS resolution for k-paas.io domains in pods

**What it does**:
- Patches cp-portal-ui deployment with hostAliases
- Injects /etc/hosts entries for all k-paas.io domains
- Maps domains to Worker LB Public IP

**When to use**: When pods show UnknownHostException errors for k-paas.io domains

**Usage**:
```bash
cd /home/ubuntu/scripts
bash 08.fix_coredns_hostaliases.sh
```

---

### 09.regenerate_apiserver_certificate.sh
**Purpose**: Regenerates API server certificates with Master LB Public IP

**What it does**:
- Creates OpenSSL configuration with all required SANs
- Generates new API server certificate including Master LB Public IP
- Signs certificate with cluster CA
- Replaces certificates on all master nodes
- Restarts API server pods

**When to use**: When external access to API server fails with x509 certificate validation errors

**Usage**:
```bash
cd /home/ubuntu/scripts
bash 09.regenerate_apiserver_certificate.sh
```

**Expected error before fix**:
```
Error while proxying request: tls: failed to verify certificate: x509: certificate is valid for 10.233.0.1, 172.16.0.157, 172.16.0.176, 127.0.0.1, ::1, 172.16.0.192, 172.16.0.254, not 210.109.52.67
```

---

### 10.post_install_fixes.sh
**Purpose**: Master orchestration script that runs all post-installation fixes

**What it does**:
- Executes scripts 07, 08, and 09 in sequence
- Provides comprehensive post-installation configuration

**When to use**: After fresh K-PaaS cluster deployment

**Usage**:
```bash
cd /home/ubuntu/scripts
bash 10.post_install_fixes.sh
```

---

## Prerequisites

### Required Variables
All scripts source `00.global_variable.sh` which should define:

```bash
# Master nodes
MASTER_COUNT=3
MASTER01_PRIVATE_IP=172.16.0.192
MASTER02_PRIVATE_IP=172.16.0.176
MASTER03_PRIVATE_IP=172.16.0.157

# Worker nodes
WORKER_COUNT=3
WORKER01_PRIVATE_IP=172.16.0.12
WORKER02_PRIVATE_IP=172.16.0.78
WORKER03_PRIVATE_IP=172.16.0.30

# Load Balancers
MASTER_LB_PUBLIC_IP=210.109.52.67
MASTER_LB_PRIVATE_IP=172.16.0.254
WORKER_LB_PUBLIC_IP=210.109.52.1
WORKER_LB_PRIVATE_IP=172.16.0.xxx

# DNS Domain
PORTAL_DOMAIN=k-paas.io
```

### SSH Configuration
Scripts assume passwordless SSH is configured:
- `/home/ubuntu/.ssh/config` with host aliases (master01, master02, master03, worker01, worker02, worker03)
- SSH keys properly configured for ubuntu user

---

## Troubleshooting

### Script 07 - Harbor Certificate Issues

**Problem**: CRI-O still can't pull images after running script

**Solutions**:
```bash
# Check certificate installation
ssh worker01 "sudo ls -l /etc/containers/certs.d/harbor.k-paas.io/"

# Verify CRI-O restart
ssh worker01 "sudo systemctl status crio"

# Test Harbor connectivity
ssh worker01 "curl -k https://harbor.k-paas.io"
```

---

### Script 08 - DNS Resolution Issues

**Problem**: Pods still show DNS errors after patching

**Solutions**:
```bash
# Verify hostAliases were applied
kubectl get deployment -n cp-portal cp-portal-ui-deployment -o yaml | grep -A 10 hostAliases

# Delete pods to force recreation
kubectl delete pod -n cp-portal -l app=cp-portal-ui-deployment

# Verify pod /etc/hosts
kubectl exec -n cp-portal <pod-name> -- cat /etc/hosts
```

---

### Script 09 - Certificate Regeneration Issues

**Problem**: API server pods in Error state after certificate replacement

**Solutions**:
```bash
# Delete problematic pods
kubectl delete pod -n kube-system kube-apiserver-master01
kubectl delete pod -n kube-system kube-apiserver-master02
kubectl delete pod -n kube-system kube-apiserver-master03

# Verify certificate SANs
ssh master01 "sudo openssl x509 -in /etc/kubernetes/ssl/apiserver.crt -text -noout | grep -A 15 'Subject Alternative Name'"

# Check API server logs
kubectl logs -n kube-system kube-apiserver-master01 --tail=50
```

**Problem**: External access still fails after certificate regeneration

**Solutions**:
```bash
# Verify Master LB Public IP in certificate
ssh master01 "sudo openssl x509 -in /etc/kubernetes/ssl/apiserver.crt -text -noout | grep '${MASTER_LB_PUBLIC_IP}'"

# Test external access
curl -k https://${MASTER_LB_PUBLIC_IP}:6443/version

# Update local kubeconfig
export KUBECONFIG=/tmp/kpaas-external-kubeconfig.yaml
kubectl version
```

---

## Common Issues

### 1. UnknownHostException: keycloak.k-paas.io

**Root Cause**: Pods cannot resolve k-paas.io domains via CoreDNS

**Solution**: Run script 08 (fix_coredns_hostaliases.sh)

---

### 2. x509: certificate is valid for ..., not <Master_LB_Public_IP>

**Root Cause**: API server certificate missing Master LB Public IP in SANs

**Solution**: Run script 09 (regenerate_apiserver_certificate.sh)

---

### 3. CRI-O cannot pull images from Harbor

**Root Cause**: Harbor's self-signed certificate not trusted by CRI-O

**Solution**: Run script 07 (fix_harbor_certificate.sh)

---

## Integration with Terraform

These scripts are designed to run after Terraform deployment. Update your Terraform provisioner module to automatically execute post-installation fixes:

```hcl
resource "null_resource" "post_install_fixes" {
  provisioner "remote-exec" {
    inline = [
      "cd /home/ubuntu/scripts",
      "bash 10.post_install_fixes.sh"
    ]
  }

  depends_on = [
    # Add dependency on K-PaaS installation completion
  ]
}
```

---

## Version Information

- **K-PaaS Version**: 1.6.2
- **Kubernetes Version**: v1.32.5
- **CRI-O Runtime**: 1.32.x
- **Kakao Cloud Provider**: terraform-provider-kakaocloud v0.2.0

---

## References

- Kubespray Configuration: `/home/ubuntu/cp-deployment/standalone/inventory/mycluster/group_vars/`
- K8s Certificates: `/etc/kubernetes/ssl/`
- CRI-O Configuration: `/etc/containers/`
- CoreDNS ConfigMap: `kubectl -n kube-system get cm coredns -o yaml`

---

## Notes

1. All scripts require sourcing `00.global_variable.sh` first
2. Scripts assume SSH connectivity to all master and worker nodes
3. API server certificate regeneration requires cluster CA keys (`/etc/kubernetes/ssl/ca.key`)
4. Scripts are idempotent and can be run multiple times safely
5. Always verify changes before running in production
