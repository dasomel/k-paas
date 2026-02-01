# K-PaaS on Kakao Cloud - Terraform Infrastructure

English | [한국어](README.ko.md)

> **Recommendation**: For new deployments, we recommend using [terraform-layered/](../terraform-layered/).
> terraform-layered/ uses fixed IPs to resolve LB Target issues and allows independent redeployment per layer.

Infrastructure as Code project that automatically deploys K-PaaS (Korean Platform as a Service) cluster on Kakao Cloud using Terraform.

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Deployed Resources](#deployed-resources)
- [Directory Structure](#directory-structure)
- [Quick Start](#quick-start)
- [Configuration Guide](#configuration-guide)
- [Deployment Process](#deployment-process)
- [Post-Deployment](#post-deployment)
- [Access Information](#access-information)
- [Troubleshooting](#troubleshooting)
- [Resource Cleanup](#resource-cleanup)

---

## Overview

This project automatically deploys a highly available K-PaaS cluster on Kakao Cloud:

- **K-PaaS Version**: 1.7.0
- **Kubernetes Version**: v1.33.5
- **Container Runtime**: CRI-O v1.33.5
- **Infrastructure**: Kakao Cloud (terraform-provider-kakaocloud v0.2.0)

### Key Features

- Fully automated infrastructure provisioning
- Highly available master nodes (3)
- External access through load balancers
- Automatic K-PaaS installation and configuration
- NFS-based storage provisioning
- LoadBalancer service via MetalLB
- Ingress Nginx controller
- Harbor private registry
- Keycloak authentication server
- CP-Portal management console

---

## Architecture

### Network Architecture

```
                                  Internet
                                      |
                    +-----------------+------------------+
                    |                                    |
              Master LB                            Worker LB
         (<Public IP>:6443)               (<Public IP>:80/443)
                    |                                    |
         +----------+----------+              +----------+----------+
         |          |          |              |          |          |
    Master-1   Master-2   Master-3       Worker-1   Worker-2   Worker-3
  (172.16.0.192) (.157)  (.254)        (172.16.0.12) (.78)   (.30)
         |          |          |              |          |          |
         +----------+----------+--------------+----------+----------+
                                |
                          VPC: 172.16.0.0/16
                       Subnet: 172.16.0.0/24
```

### Component Configuration

#### Control Plane (Master Nodes)
- **Count**: 3 (High Availability)
- **Role**: Kubernetes API Server, etcd, Controller Manager, Scheduler
- **Access**: External access through Master LB

#### Worker Nodes
- **Count**: 3
- **Role**: Application workload execution
- **Access**: HTTP/HTTPS traffic through Worker LB

#### Load Balancers
- **Master LB**: Kubernetes API Server access (ports 6443, 2379)
- **Worker LB**: Ingress traffic (ports 80, 443)

---

## Prerequisites

### Required Software

- **Terraform**: v1.0 or higher
- **SSH Client**: For server access
- **kubectl**: For Kubernetes cluster management (optional)

### Kakao Cloud Requirements

1. **Kakao Cloud Account**
2. **Create Application Credential**:
   ```
   - Create in IAM > Application Credentials
   - Save ID and Secret
   ```

3. **Create SSH KeyPair**:
   ```
   - Create in Compute > Key Pairs
   - Name: KPAAS_KEYPAIR
   - Download and save PEM file
   ```

4. **Check Quotas**:
   - Instance: Minimum 6
   - vCPU: Minimum 24
   - Memory: Minimum 96GB
   - Volume: Minimum 1.2TB
   - Public IP: Minimum 8
   - Load Balancer: 2

---

## Deployed Resources

### Current Deployment Configuration

#### Network Resources
| Resource Type | Name | CIDR/Address | ID |
|--------------|------|--------------|-----|
| VPC | test-kpaas | 172.16.0.0/16 | abe85940-b9ca-4a1c-badc-3c7f3c259292 |
| Subnet | main_subnet | 172.16.0.0/24 | a2a91e45-c2c6-4ea7-be69-693dae9d0f0a |
| Security Group | kpaas-security-group | - | e93649b5-4408-4bf0-b77d-378b4e3b0aa5 |

#### Compute Resources
| Node Type | Count | Private IP | Public IP | Instance ID |
|----------|------|------------|-----------|-------------|
| Master-1 | 1 | 172.16.0.192 | \<Public IP\> | 4bbf45d5-683f-49ef-84d4-efb405a8f74e |
| Master-2 | 1 | 172.16.0.157 | \<Public IP\> | 6c8b403d-9859-46ff-82ba-94cf2a6f52da |
| Master-3 | 1 | 172.16.0.254 | \<Public IP\> | 3e9b3cb0-af39-46ca-b0ef-0f755730df49 |
| Worker-1 | 1 | 172.16.0.12 | \<Public IP\> | bc78bcb1-a9a2-492d-8f9b-af8943c9833c |
| Worker-2 | 1 | 172.16.0.78 | \<Public IP\> | 3af122cd-902b-4132-aea7-981a0079959c |
| Worker-3 | 1 | 172.16.0.30 | \<Public IP\> | 5463bb52-45a2-4d88-92d3-2e0c8d5f3e8b |

**Instance Spec**: t1i.xlarge (vCPU: 4, Memory: 16GB, Storage: 200GB)

#### Load Balancer Resources
| LB Type | Public IP | VIP | LB ID |
|---------|-----------|-----|-------|
| Master LB | \<Public IP\> | 172.16.0.176 | f516c85f-44a5-4f6f-835d-551804c39af1 |
| Worker LB | \<Public IP\> | 172.16.0.53 | 685bcf56-7e4e-4d6e-89d9-4111871578be |

---

## Directory Structure

```
terraform/
├── README.md                    # This document
├── ARCHITECTURE.md              # Detailed architecture document
├── main.tf                      # Main Terraform configuration
├── variables.tf                 # Variable definitions
├── outputs.tf                   # Output definitions
├── terraform.tfvars             # Variable values (Contains credentials - add to .gitignore)
├── provider.tf                  # Provider configuration
├── cloud-init.yaml              # Instance initialization script
├── KPAAS_KEYPAIR.pem           # SSH key (Security sensitive!)
│
├── modules/                     # Terraform modules
│   ├── network/                # VPC, Subnet creation
│   ├── security/               # Security Group creation
│   ├── compute/                # Master, Worker instances
│   ├── loadbalancer/           # Master, Worker LB
│   └── provisioner/            # K-PaaS installation automation
│
└── generated/                   # Auto-generated scripts
    ├── cp-cluster-vars.sh      # Kubespray variables
    ├── 00.global_variable.sh   # Global variables
    └── ...
```

---

## Quick Start

### 1. Clone Repository and Navigate

```bash
cd csp/kakao-cloud/terraform
```

### 2. Configure Terraform Variables

Edit `terraform.tfvars` file to input Kakao Cloud credentials:

```hcl
# Kakao Cloud Credentials
application_credential_id     = "your-credential-id"
application_credential_secret = "your-credential-secret"

# SSH Key
key_name     = "KPAAS_KEYPAIR"
ssh_key_path = "./KPAAS_KEYPAIR.pem"

# Use default values for the rest
```

### 3. Place SSH Key

```bash
# Copy the PEM file downloaded from Kakao Cloud to the project directory
cp ~/Downloads/KPAAS_KEYPAIR.pem ./
chmod 400 ./KPAAS_KEYPAIR.pem
```

### 4. Initialize and Deploy Terraform

```bash
# Initialize Terraform
terraform init

# Review plan
terraform plan

# Deploy (takes approximately 2 hours)
terraform apply -auto-approve

# For better stability with slow API
terraform apply -parallelism=3 -auto-approve
```

### 5. Check Deployment Status

```bash
# Check output information
terraform output

# SSH to Master-1 to check installation logs
ssh -i ./KPAAS_KEYPAIR.pem ubuntu@<MASTER1_PUBLIC_IP>
tail -f /home/ubuntu/kpaas_install.log
```

---

## Configuration Guide

### Key terraform.tfvars Settings

```hcl
#####################################################################
# Network Configuration
#####################################################################
vpc_name                = "test-kpaas"          # VPC name
vpc_cidr                = "172.16.0.0/16"       # VPC CIDR
subnet_cidr             = "172.16.0.0/24"       # Subnet CIDR
availability_zone       = "kr-central-2-a"      # Availability zone

#####################################################################
# Compute Configuration
#####################################################################
master_count     = 3                     # Master node count (3 recommended for HA)
worker_count     = 3                     # Worker node count
image_name       = "Ubuntu 24.04"        # OS image
instance_flavor  = "t1i.xlarge"          # Instance type (vCPU:4, Memory:16GB)
volume_size      = 200                   # Disk size (GB)

#####################################################################
# K-PaaS Configuration
#####################################################################
metallb_ip_range     = "172.16.0.210-172.16.0.250"  # MetalLB IP pool
ingress_nginx_ip     = "172.16.0.201"               # Ingress Nginx LB IP
portal_domain        = "k-paas.io"                  # Portal domain
auto_install_kpaas   = true                         # Enable auto installation
```

### Instance Type Selection Guide

| Type | vCPU | Memory | Use Case | Recommended |
|------|------|--------|----------|-------------|
| t1i.large | 2 | 8GB | Dev/Test | ❌ (Below minimum) |
| t1i.xlarge | 4 | 16GB | Small production | ✅ (Current) |
| t1i.2xlarge | 8 | 32GB | Medium production | ✅ (Recommended) |
| t1i.4xlarge | 16 | 64GB | Large production | ✅ |

---

## Deployment Process

### Terraform Execution Stages

1. **Module: Network** (~60 minutes)
   - VPC creation
   - Subnet creation
   - Includes Kakao Cloud API response wait time

2. **Module: Security** (~5 minutes)
   - Security Group creation
   - Firewall rules configuration

3. **Module: Compute** (~15 minutes)
   - Create 3 Master instances
   - Create 3 Worker instances
   - Public IP assignment
   - cloud-init execution

4. **Module: LoadBalancer** (~10 minutes)
   - Master LB creation and configuration
   - Worker LB creation and configuration
   - Target Group configuration
   - Health Check configuration

5. **Module: Provisioner** (~30 minutes)
   - SSH configuration and host registration
   - NFS server setup
   - Kubernetes cluster setup via Kubespray
   - K-PaaS component installation
   - CP-Portal installation

**Total estimated time**: ~2 hours (Infrastructure 90min + K-PaaS installation 30min)

> **Note**: Kakao Cloud API response time is slow, especially for Network module.

---

## Post-Deployment

### 1. Check Cluster Status

```bash
# SSH to Master-1
ssh -i ./KPAAS_KEYPAIR.pem ubuntu@<MASTER1_PUBLIC_IP>

# Check node status
kubectl get nodes

# Check all Pod status
kubectl get pods -A
```

### 2. External kubectl Access Setup

```bash
# Download Kubeconfig file
scp -i ./KPAAS_KEYPAIR.pem ubuntu@<MASTER1_PUBLIC_IP>:/home/ubuntu/.kube/config ./kubeconfig

# Set Kubeconfig
export KUBECONFIG=$(pwd)/kubeconfig

# Test cluster access
kubectl cluster-info
```

### 3. /etc/hosts Configuration (Local Machine)

Add the following to your local machine's `/etc/hosts` for service access:

```bash
# K-PaaS Services
<WORKER_LB_PUBLIC_IP> k-paas.io portal.k-paas.io harbor.k-paas.io keycloak.k-paas.io openbao.k-paas.io chartmuseum.k-paas.io
<MASTER_LB_PUBLIC_IP> cluster-endpoint
```

---

## Access Information

### K-PaaS Services

All services are accessed through Worker LB:

| Service | URL | Default Account |
|---------|-----|-----------------|
| **CP-Portal** | https://portal.k-paas.io | admin / See install log |
| **Harbor** | https://harbor.k-paas.io | admin / See install log |
| **Keycloak** | https://keycloak.k-paas.io | admin / See install log |
| **OpenBao** | https://openbao.k-paas.io | Root token: See install log |

### SSH Access

```bash
# Master-1
ssh -i ./KPAAS_KEYPAIR.pem ubuntu@<MASTER1_PUBLIC_IP>

# Worker-1
ssh -i ./KPAAS_KEYPAIR.pem ubuntu@<WORKER1_PUBLIC_IP>
```

---

## Troubleshooting

### Check K-PaaS Installation Progress

```bash
# SSH to Master-1
ssh -i ./KPAAS_KEYPAIR.pem ubuntu@<MASTER1_PUBLIC_IP>

# Full installation log
tail -f /home/ubuntu/kpaas_install.log

# Kubernetes cluster installation log
tail -f /home/ubuntu/cp-deployment/standalone/cluster-install.log

# Portal installation log
tail -f /home/ubuntu/workspace/container-platform/cp-portal-deployment/script/deploy-portal-result.log
```

### Debugging Commands

```bash
# Check node status
kubectl get nodes -o wide

# Check Pod status
kubectl get pods -A -o wide

# Check specific Pod logs
kubectl logs -n <namespace> <pod-name>

# Check services
kubectl get svc -A

# Check Ingress
kubectl get ingress -A
```

---

## Resource Cleanup

### Delete All Infrastructure

```bash
# Delete all resources created by Terraform
terraform destroy -auto-approve
```

**Warnings**:
- Back up important data before deletion
- Recovery is not possible after deletion
- Public IPs are immediately released and cannot be reused

---

## Additional Documentation

- **[../docs/ARCHITECTURE.md](../docs/ARCHITECTURE.md)**: Detailed architecture and design document
- **[../docs/README_POST_INSTALL_FIXES.md](../docs/README_POST_INSTALL_FIXES.md)**: Post-installation fix guide
- **[../docs/SCRIPT_TEMPLATES.md](../docs/SCRIPT_TEMPLATES.md)**: Script templates
- **[../docs/k-paas.md](../docs/k-paas.md)**: K-PaaS installation requirements

---

## Version Information

- **Terraform**: >= 1.0
- **Provider**: kakaocloud v0.2.0
- **K-PaaS**: 1.7.0
- **Kubernetes**: v1.33.5
- **CRI-O**: v1.33.5
- **Ubuntu**: 24.04 LTS
