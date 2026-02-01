# K-PaaS on Kakao Cloud - Layered Terraform

[English](README.md) | 한국어

Kakao Cloud의 느린 리소스 생성 시간을 고려한 3-Layer Terraform 구조입니다.

## 구조

```
terraform-layered/
├── 01-network/        # VPC, Subnet (1회 생성, ~60분)
├── 02-loadbalancer/   # LB, Security Group (1회 생성, ~10분)
└── 03-cluster/        # Compute, Provisioner (반복 가능, ~15분 + 설치 30분)
```

## 장점

| 레이어 | 생성 시간 | 재생성 빈도 | 비고 |
|--------|----------|------------|------|
| 01-network | ~60분 | 거의 없음 | VPC/Subnet은 한 번만 생성 |
| 02-loadbalancer | ~10분 | 거의 없음 | LB는 고정 IP Target 사용 |
| 03-cluster | ~15분 | 테스트 시 자주 | 인스턴스만 재생성 |

**총 절약 시간**: 클러스터 재생성 시 85분 → 45분 (Network/LB 유지)

## 핵심: 고정 IP 사용

```hcl
# 02-loadbalancer: LB Target으로 고정 IP 설정
variable "master_private_ips" {
  default = ["172.16.0.101", "172.16.0.102", "172.16.0.103"]
}

# 03-cluster: 인스턴스를 동일한 고정 IP로 생성
subnets = [
  {
    id         = local.subnet_id
    private_ip = "172.16.0.101"  # 고정 IP!
  }
]
```

## 사용법

### 1. 초기 설정

각 레이어에 `terraform.tfvars` 생성:

```bash
# 01-network/terraform.tfvars
cat > 01-network/terraform.tfvars << 'EOF'
application_credential_id     = "your-credential-id"
application_credential_secret = "your-credential-secret"
EOF

# 02-loadbalancer, 03-cluster도 동일하게 설정
cp 01-network/terraform.tfvars 02-loadbalancer/
cp 01-network/terraform.tfvars 03-cluster/
```

### 2. 한 번에 배포 (권장)

```bash
# 전체 배포 (Network → LB → Cluster)
./deploy.sh all

# 또는 간단히
./deploy.sh
```

### 3. 개별 레이어 배포

```bash
./deploy.sh network   # Network만
./deploy.sh lb        # LoadBalancer만
./deploy.sh cluster   # Cluster만
```

### 4. 클러스터만 재생성 (빠름)

```bash
# 클러스터만 삭제하고 다시 생성 (Network/LB 유지)
./deploy.sh destroy-cluster
./deploy.sh cluster
```

### 5. 전체 삭제

```bash
./deploy.sh destroy
```

### deploy.sh 명령어

| 명령어 | 설명 |
|--------|------|
| `all` | 전체 배포 (기본값) |
| `network` | Network 레이어만 |
| `lb` | LoadBalancer 레이어만 |
| `cluster` | Cluster 레이어만 |
| `destroy` | 전체 삭제 |
| `destroy-cluster` | Cluster만 삭제 (빠른 재배포용) |
| `status` | 배포 상태 확인 |

## 고정 IP 구성

| 노드 | Private IP |
|------|------------|
| master-1 | 172.16.0.101 |
| master-2 | 172.16.0.102 |
| master-3 | 172.16.0.103 |
| worker-1 | 172.16.0.111 |
| worker-2 | 172.16.0.112 |
| worker-3 | 172.16.0.113 |

## 주의사항

1. **순서 준수**: 반드시 01 → 02 → 03 순서로 배포
2. **State 파일**: 각 레이어의 `terraform.tfstate`는 상위 레이어에서 참조
3. **삭제 순서**: 삭제 시 03 → 02 → 01 역순으로

## 설치 확인

```bash
# Master-1 SSH 접속
ssh -i ../terraform/KPAAS_KEYPAIR.pem ubuntu@<master-1-public-ip>

# 설치 로그 확인
tail -f /home/ubuntu/kpaas_install.log

# 클러스터 상태 확인
kubectl get nodes
```

## 서비스 접속

| 서비스 | URL | 설명 |
|--------|-----|------|
| Portal | https://portal.k-paas.io | K-PaaS 관리 포털 |
| Harbor | https://harbor.k-paas.io | 컨테이너 레지스트리 |
| Keycloak | https://keycloak.k-paas.io | 인증 서버 |
| OpenBao | https://openbao.k-paas.io | Secret 관리 |
| ChartMuseum | https://chartmuseum.k-paas.io | Helm Chart 저장소 |

**hosts 파일 설정**:
```
<worker-lb-public-ip> k-paas.io portal.k-paas.io harbor.k-paas.io keycloak.k-paas.io openbao.k-paas.io chartmuseum.k-paas.io
```
