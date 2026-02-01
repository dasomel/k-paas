# K-PaaS on Kakao Cloud - Documentation

English | [한국어](README.ko.md)

This directory contains documentation for K-PaaS Kakao Cloud deployment.

## Document List

### Getting Started

| Document | Description |
|----------|-------------|
| [../terraform/README.md](../terraform/README.md) | Main Guide: Quick Start, Deployment, Configuration |
| [k-paas.md](k-paas.md) | K-PaaS Installation Requirements (Instance Specs) |

### Architecture

| Document | Description |
|----------|-------------|
| [ARCHITECTURE.md](ARCHITECTURE.md) | Detailed Architecture and Design Document |
| [ARCHITECTURE_DIAGRAMS.md](ARCHITECTURE_DIAGRAMS.md) | Architecture Diagrams |
| [PROJECT_ANALYSIS.md](PROJECT_ANALYSIS.md) | Project Analysis Document |

### Post-Installation

| Document | Description |
|----------|-------------|
| [README_POST_INSTALL_FIXES.md](README_POST_INSTALL_FIXES.md) | Post-Installation Fix Guide |
| [POST_INSTALL_FIXES_SUMMARY.md](POST_INSTALL_FIXES_SUMMARY.md) | Post-Installation Summary |
| [SCRIPT_TEMPLATES.md](SCRIPT_TEMPLATES.md) | Script Template Documentation |

## Version Information

| Component | Version |
|-----------|---------|
| K-PaaS | 1.7.0 |
| Kubernetes | v1.33.5 |
| CRI-O | v1.33.5 |
| Ubuntu | 24.04 LTS |
| Terraform Provider | kakaocloud v0.2.0 |

## Deployment Configuration

| Node Type | Count | Spec |
|-----------|-------|------|
| Master | 3 | t1i.xlarge (4 vCPU, 16GB) |
| Worker | 3 | t1i.xlarge (4 vCPU, 16GB) |
| Load Balancer | 2 | Master LB, Worker LB |

## Services

| Service | URL | Description |
|---------|-----|-------------|
| CP-Portal | https://portal.k-paas.io | K-PaaS Management Portal |
| Harbor | https://harbor.k-paas.io | Container Registry |
| Keycloak | https://keycloak.k-paas.io | Authentication Server |
| OpenBao | https://openbao.k-paas.io | Secret Management |

## Related Links

- [K-PaaS GitHub](https://github.com/K-PaaS)
- [Kakao Cloud Console](https://console.kakaocloud.io)
- [Terraform Kakao Cloud Provider](https://registry.terraform.io/providers/kakaoenterprise/kakaocloud)
