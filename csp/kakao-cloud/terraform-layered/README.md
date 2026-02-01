# K-PaaS on Kakao Cloud - Layered Terraform

English | [한국어](README.ko.md)

A 3-Layer Terraform structure designed for Kakao Cloud's slow resource creation time.

## Structure

```
terraform-layered/
├── 01-network/        # VPC, Subnet (one-time creation, ~60min)
├── 02-loadbalancer/   # LB, Security Group (one-time creation, ~10min)
└── 03-cluster/        # Compute, Provisioner (repeatable, ~15min + 30min installation)
```

## Benefits

| Layer | Creation Time | Recreation Frequency | Notes |
|-------|--------------|---------------------|-------|
| 01-network | ~60min | Rarely | VPC/Subnet created once |
| 02-loadbalancer | ~10min | Rarely | LB uses fixed IP targets |
| 03-cluster | ~15min | Frequently during testing | Only instances recreated |

**Total time saved**: Cluster recreation 85min → 45min (keeps Network/LB)

## Key Feature: Fixed IP Usage

```hcl
# 02-loadbalancer: Set fixed IPs as LB targets
variable "master_private_ips" {
  default = ["172.16.0.101", "172.16.0.102", "172.16.0.103"]
}

# 03-cluster: Create instances with the same fixed IPs
subnets = [
  {
    id         = local.subnet_id
    private_ip = "172.16.0.101"  # Fixed IP!
  }
]
```

## Usage

### 1. Initial Setup

Create `terraform.tfvars` for each layer:

```bash
# 01-network/terraform.tfvars
cat > 01-network/terraform.tfvars << 'EOF'
application_credential_id     = "your-credential-id"
application_credential_secret = "your-credential-secret"
EOF

# Copy to 02-loadbalancer and 03-cluster
cp 01-network/terraform.tfvars 02-loadbalancer/
cp 01-network/terraform.tfvars 03-cluster/
```

### 2. Full Deployment (Recommended)

```bash
# Full deployment (Network → LB → Cluster)
./deploy.sh all

# Or simply
./deploy.sh
```

### 3. Individual Layer Deployment

```bash
./deploy.sh network   # Network only
./deploy.sh lb        # LoadBalancer only
./deploy.sh cluster   # Cluster only
```

### 4. Cluster-Only Recreation (Fast)

```bash
# Delete and recreate cluster only (keeps Network/LB)
./deploy.sh destroy-cluster
./deploy.sh cluster
```

### 5. Full Cleanup

```bash
./deploy.sh destroy
```

### deploy.sh Commands

| Command | Description |
|---------|-------------|
| `all` | Full deployment (default) |
| `network` | Network layer only |
| `lb` | LoadBalancer layer only |
| `cluster` | Cluster layer only |
| `destroy` | Full cleanup |
| `destroy-cluster` | Cluster only cleanup (for fast redeployment) |
| `status` | Check deployment status |

## Fixed IP Configuration

| Node | Private IP |
|------|------------|
| master-1 | 172.16.0.101 |
| master-2 | 172.16.0.102 |
| master-3 | 172.16.0.103 |
| worker-1 | 172.16.0.111 |
| worker-2 | 172.16.0.112 |
| worker-3 | 172.16.0.113 |

## Important Notes

1. **Follow the order**: Must deploy in order 01 → 02 → 03
2. **State files**: Each layer's `terraform.tfstate` is referenced by upper layers
3. **Deletion order**: Delete in reverse order 03 → 02 → 01

## Installation Verification

```bash
# SSH to Master-1
ssh -i ../terraform/KPAAS_KEYPAIR.pem ubuntu@<master-1-public-ip>

# Check installation logs
tail -f /home/ubuntu/kpaas_install.log

# Check cluster status
kubectl get nodes
```

## Service Access

| Service | URL | Description |
|---------|-----|-------------|
| Portal | https://portal.k-paas.io | K-PaaS Management Portal |
| Harbor | https://harbor.k-paas.io | Container Registry |
| Keycloak | https://keycloak.k-paas.io | Authentication Server |
| OpenBao | https://openbao.k-paas.io | Secret Management |
| ChartMuseum | https://chartmuseum.k-paas.io | Helm Chart Repository |

**hosts file configuration**:
```
<worker-lb-public-ip> k-paas.io portal.k-paas.io harbor.k-paas.io keycloak.k-paas.io openbao.k-paas.io chartmuseum.k-paas.io
```
