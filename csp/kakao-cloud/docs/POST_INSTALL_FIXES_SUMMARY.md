# K-PaaS Post-Installation Fixes - Summary

## Overview

This document summarizes the post-installation fixes created for K-PaaS deployment on Kakao Cloud. These scripts address common issues that occur after cluster deployment.

## Scripts Created

| Script | Purpose | Location |
|--------|---------|----------|
| `07.fix_harbor_certificate.sh` | Configure Harbor self-signed certificate on workers | `/home/ubuntu/scripts/` |
| `08.fix_coredns_hostaliases.sh` | Fix pod DNS resolution for k-paas.io domains | `/home/ubuntu/scripts/` |
| `09.regenerate_apiserver_certificate.sh` | Add Master LB Public IP to API server certificate | `/home/ubuntu/scripts/` |
| `10.post_install_fixes.sh` | Master script that runs all fixes | `/home/ubuntu/scripts/` |

## Documentation Created

| Document | Purpose | Location |
|----------|---------|----------|
| `README_POST_INSTALL_FIXES.md` | Complete guide to all post-install fix scripts | `/Users/m/Documents/IdeaProjects/k-paas/scripts/` |
| `SCRIPT_TEMPLATES.md` | Reusable script templates for new deployments | `/Users/m/Documents/IdeaProjects/k-paas/scripts/` |
| `POST_INSTALL_FIXES_SUMMARY.md` | This summary document | `/Users/m/Documents/IdeaProjects/k-paas/scripts/` |

---

## Problems Solved

### 1. Harbor Certificate Issue
**Problem**: Worker nodes cannot pull images from Harbor private registry due to untrusted self-signed certificate.

**Error**:
```
x509: certificate signed by unknown authority
```

**Solution**: Script `07.fix_harbor_certificate.sh`
- Downloads Harbor certificate from master node
- Installs to system CA trust store on all workers
- Configures CRI-O to trust Harbor registry
- Restarts CRI-O service

---

### 2. Pod DNS Resolution Issue
**Problem**: Pods cannot resolve k-paas.io domains (keycloak, harbor, portal, etc.)

**Error**:
```
Caused by: java.net.UnknownHostException: keycloak.k-paas.io
```

**Solution**: Script `08.fix_coredns_hostaliases.sh`
- Patches deployments with Kubernetes hostAliases feature
- Injects /etc/hosts entries directly into pod spec
- Maps all k-paas.io domains to Worker LB Public IP

**Why hostAliases instead of CoreDNS**:
- CoreDNS hosts plugin returned NXDOMAIN despite configuration
- hostAliases provides guaranteed DNS resolution at pod level
- No dependency on cluster DNS functionality

---

### 3. External API Server Access Issue
**Problem**: Cannot access Kubernetes API server from external network via Master LB Public IP

**Error**:
```
Error while proxying request: tls: failed to verify certificate:
x509: certificate is valid for 10.233.0.1, 172.16.0.157, 172.16.0.176,
127.0.0.1, ::1, 172.16.0.192, 172.16.0.254, not 210.109.52.67
```

**Solution**: Script `09.regenerate_apiserver_certificate.sh`
- Creates OpenSSL configuration with all required SANs
- Includes Master LB Public IP in Subject Alternative Names
- Generates new CSR and signs with cluster CA
- Replaces certificates on all 3 master nodes
- Restarts API server pods

**Kubespray Configuration Updated**:
File: `/home/ubuntu/cp-deployment/standalone/inventory/mycluster/group_vars/k8s_cluster/k8s-cluster.yml`
```yaml
supplementary_addresses_in_ssl_keys: [210.109.52.67]
```

---

## Quick Start

### For New Deployment

1. **Extract Terraform outputs**:
```bash
cd /Users/m/Documents/IdeaProjects/k-paas/csp/kakao-cloud/test2
terraform output -json > /tmp/tf-outputs.json
```

2. **Update global variables**:
```bash
# Edit /home/ubuntu/scripts/00.global_variable.sh with:
# - Master and worker private IPs
# - Master and worker LB public/private IPs
# - Node counts
```

3. **Configure SSH access**:
```bash
# Set up SSH config for passwordless access to master01, master02, master03, worker01, worker02, worker03
```

4. **Run post-installation fixes**:
```bash
ssh master01
cd /home/ubuntu/scripts
bash 10.post_install_fixes.sh
```

---

## Verification Steps

### After Running Scripts

1. **Verify Harbor Certificate**:
```bash
# On any worker node
sudo openssl x509 -in /etc/containers/certs.d/harbor.k-paas.io/ca.crt -text -noout
sudo systemctl status crio

# Test image pull
sudo crictl pull harbor.k-paas.io/library/nginx:latest
```

2. **Verify Pod DNS Resolution**:
```bash
# Check deployment hostAliases
kubectl get deployment -n cp-portal cp-portal-ui-deployment -o yaml | grep -A 15 hostAliases

# Check pod status
kubectl get pods -n cp-portal

# Verify /etc/hosts in pod
kubectl exec -n cp-portal <pod-name> -- cat /etc/hosts | grep k-paas.io
```

3. **Verify External API Server Access**:
```bash
# From local machine
export KUBECONFIG=/tmp/kpaas-external-kubeconfig.yaml
kubectl version
kubectl get nodes

# Verify certificate SANs
ssh master01 "sudo openssl x509 -in /etc/kubernetes/ssl/apiserver.crt -text -noout | grep -A 15 'Subject Alternative Name'"
```

---

## Integration with Terraform

### Option 1: Manual Execution
Run scripts manually after Terraform completes cluster deployment.

### Option 2: Automated Provisioner
Add to Terraform configuration:

```hcl
resource "null_resource" "post_install_fixes" {
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(var.ssh_key_path)
    host        = module.loadbalancer.master_lb_public_ip
  }

  provisioner "file" {
    source      = "${path.module}/../../../scripts/07.fix_harbor_certificate.sh"
    destination = "/home/ubuntu/scripts/07.fix_harbor_certificate.sh"
  }

  provisioner "file" {
    source      = "${path.module}/../../../scripts/08.fix_coredns_hostaliases.sh"
    destination = "/home/ubuntu/scripts/08.fix_coredns_hostaliases.sh"
  }

  provisioner "file" {
    source      = "${path.module}/../../../scripts/09.regenerate_apiserver_certificate.sh"
    destination = "/home/ubuntu/scripts/09.regenerate_apiserver_certificate.sh"
  }

  provisioner "file" {
    source      = "${path.module}/../../../scripts/10.post_install_fixes.sh"
    destination = "/home/ubuntu/scripts/10.post_install_fixes.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ubuntu/scripts/*.sh",
      "cd /home/ubuntu/scripts",
      "bash 10.post_install_fixes.sh"
    ]
  }

  depends_on = [
    module.provisioner  # Wait for K-PaaS installation to complete
  ]
}
```

---

## Known Limitations

1. **Scripts require passwordless SSH**: Must configure SSH keys and config for all nodes
2. **Fixed namespace**: Currently hardcoded for `cp-portal` namespace
3. **Single deployment**: Only patches `cp-portal-ui-deployment` - other deployments may need similar fixes
4. **Manual variable updates**: Must manually update `00.global_variable.sh` for each deployment

---

## Future Improvements

1. **Auto-detect IPs**: Extract IPs from Terraform state automatically
2. **Dynamic namespace detection**: Automatically find and patch all affected deployments
3. **Idempotent checks**: Add checks to skip already-applied fixes
4. **Rollback capability**: Add ability to restore previous certificates
5. **Integration testing**: Add automated verification after each script

---

## Environment Information

### Previous Cluster (Reference)
```
Deployment Date: 2025-11-27
Master LB Public IP: 210.109.52.67
Worker LB Public IP: 210.109.52.1

Master Nodes:
- master01: 172.16.0.192
- master02: 172.16.0.176
- master03: 172.16.0.157

Worker Nodes:
- worker01: 172.16.0.12
- worker02: 172.16.0.78
- worker03: 172.16.0.30

Software Versions:
- K-PaaS: v1.6.2
- Kubernetes: v1.32.5
- CRI-O: v1.32.x
- Terraform Provider: kakaocloud v0.2.0
```

---

## Support

For issues or questions:
1. Check `README_POST_INSTALL_FIXES.md` for troubleshooting steps
2. Review script templates in `SCRIPT_TEMPLATES.md`
3. Verify global variables in `00.global_variable.sh`
4. Check Kubernetes logs: `kubectl logs -n kube-system <pod-name>`
5. Review CRI-O logs: `sudo journalctl -u crio -f`

---

## Related Files

- **Terraform Configuration**: `/Users/m/Documents/IdeaProjects/k-paas/csp/kakao-cloud/test2/`
- **K-PaaS Deployment**: `/home/ubuntu/cp-deployment/standalone/`
- **Kubespray Configuration**: `/home/ubuntu/cp-deployment/standalone/inventory/mycluster/group_vars/`
- **Kubernetes Certificates**: `/etc/kubernetes/ssl/`
- **CRI-O Configuration**: `/etc/containers/`

---

## Change Log

| Date | Version | Changes |
|------|---------|---------|
| 2025-11-27 | 1.0 | Initial scripts created for cluster at 210.109.52.67 |
| 2025-11-27 | 1.1 | Documentation created (README, Templates, Summary) |
