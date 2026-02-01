# Changelog

K-PaaS Local Installation Automation Tool Change History

English | [한국어](CHANGELOG.ko.md)

---

## [2.2.0] - 2026-01-24

### K-PaaS v1.7.0 Support

#### Added

##### ARM64 Portal Support
- `ghcr.io/dasomel-k-pass` ARM64 Portal image support
  - Full components: cp-portal-ui, cp-portal-api, cp-catalog-api, cp-metrics-api, etc.
  - Automatic service name mapping (cp-portal-xxx → cp-xxx)
  - Automatic Ingress backend service name patching

##### ARM64 Harbor Support
- `ghcr.io/dasomel/goharbor` ARM64 Harbor image support
  - Automatic hotfix for registry-photon, harbor-registryctl images
  - `install_cert.sh` script injection with proper permissions
  - Automated image build and Worker node deployment via Podman

##### Infrastructure Automation
- Init container SSL certificate injection (no image rebuild required)
- Keycloak Bitnami Helm chart automated deployment (existing script skipped)
- Automatic catalog-api config.env ConfigMap generation
- OpenBao unseal key automatic management

##### Kakao Cloud Deployment
- `terraform-layered/` 3-Layer architecture added (Network → LoadBalancer → Cluster)
- Fixed IP-based LB Target configuration (172.16.0.101-103, 172.16.0.111-113)
- `deploy.sh` unified deployment script
- CoreDNS custom hosts automatic configuration

##### Standard Framework Sample
- egovframe-web-sample multi-architecture build support (amd64/arm64)
- Container image signing (cosign) support
- SBOM (SPDX) generation support

#### Changed
- Configuration variables unified (consolidated to `00.global_variable.sh`)
- ARM64 branching integrated inline within scripts
- migration-ui probe settings auto-patched (port 8097, path /cpmigui)
- MariaDB downgraded to 10.11 (ARM64 compatibility)
- cp-admin authentication changed to mysql_native_password (JDBC compatibility)
- Helm install → `helm upgrade --install` for idempotency

#### Removed
- `scripts/variable/` directory (unused)
- `scripts/arm/helm/` directory (integrated into scripts)
- `scripts/arm/*.sh` hotfix scripts (integrated into scripts)

---

## [2.1.0] - 2026-01-07

### K-PaaS v1.6.2 Support

#### Added
- ARM64 (Apple Silicon) environment support
- Harbor ARM64 image hotfix script
- Portal UI certificate hotfix script

#### Changed
- Vagrant Box changed to dasomel/ubuntu-24.04
- ARM64 image support improvements

---

## [2.0.0] - 2024-12-20

### K-PaaS v1.6.2 Support

#### Added
- ARM64 architecture support added
- VMware Desktop Provider support
- Ubuntu 24.04 (bento/ubuntu-24.04) base image

#### Changed
- K-PaaS v1.5.2 → v1.6.2 upgrade
- Vagrant Box version update

---

## [1.0.1] - 2024-09-15

### K-PaaS v1.5.2 Support

#### Changed
- K-PaaS v1.5.0 → v1.5.2 upgrade
- Installation script stability improvements

#### Fixed
- Removed kubectl version change script

---

## [1.0.0] - 2024-09-08

### Initial Release

#### Added
- Vagrant-based K-PaaS local installation automation
- VirtualBox Provider support
- 6-node cluster configuration (LB 2, Master 2, Worker 2)
- HAProxy + Keepalived high availability load balancer
- Kubespray-based Kubernetes installation
- K-PaaS Container Platform Portal installation

---

## Version Compatibility

| Local Tool | K-PaaS CP | Kubernetes | Ubuntu | Architecture |
|------------|-----------|------------|--------|--------------|
| 2.2.0 | v1.7.0 | v1.33.5 | 24.04 | amd64, arm64 |
| 2.1.0 | v1.6.2 | v1.31+ | 24.04 | amd64, arm64 |
| 2.0.0 | v1.6.2 | v1.30+ | 24.04 | amd64, arm64 |
| 1.0.1 | v1.5.2 | v1.28+ | 22.04 | amd64 |
| 1.0.0 | v1.5.0 | v1.28+ | 22.04 | amd64 |
