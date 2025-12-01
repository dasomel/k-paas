# K-PaaS on Kakao Cloud - Terraform Infrastructure

Terraform을 사용하여 Kakao Cloud에 K-PaaS (Korean Platform as a Service) 클러스터를 자동으로 배포하는 Infrastructure as Code 프로젝트입니다.

## 목차

- [개요](#개요)
- [아키텍처](#아키텍처)
- [사전 요구사항](#사전-요구사항)
- [배포된 리소스](#배포된-리소스)
- [디렉토리 구조](#디렉토리-구조)
- [빠른 시작](#빠른-시작)
- [설정 가이드](#설정-가이드)
- [배포 과정](#배포-과정)
- [배포 후 작업](#배포-후-작업)
- [접속 정보](#접속-정보)
- [문제 해결](#문제-해결)
- [리소스 정리](#리소스-정리)

---

## 개요

이 프로젝트는 Kakao Cloud에 다음과 같은 고가용성 K-PaaS 클러스터를 자동으로 배포합니다:

- **K-PaaS 버전**: 1.6.2
- **Kubernetes 버전**: v1.32.5
- **컨테이너 런타임**: CRI-O v1.32.x
- **인프라**: Kakao Cloud (terraform-provider-kakaocloud v0.1.4)

### 주요 기능

- 완전 자동화된 인프라 프로비저닝
- 고가용성 마스터 노드 (3개)
- 로드 밸런서를 통한 외부 접근
- 자동 K-PaaS 설치 및 설정
- NFS 기반 스토리지 프로비저닝
- MetalLB를 통한 LoadBalancer 서비스
- Ingress Nginx 컨트롤러
- Harbor 프라이빗 레지스트리
- Keycloak 인증 서버
- CP-Portal 관리 콘솔

---

## 아키텍처

### 네트워크 아키텍처

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

### 컴포넌트 구성

#### Control Plane (Master Nodes)
- **개수**: 3개 (고가용성)
- **역할**: Kubernetes API Server, etcd, Controller Manager, Scheduler
- **접근**: Master LB를 통한 외부 접근

#### Worker Nodes
- **개수**: 3개
- **역할**: 애플리케이션 워크로드 실행
- **접근**: Worker LB를 통한 HTTP/HTTPS 트래픽

#### Load Balancers
- **Master LB**: Kubernetes API Server 접근 (포트 6443, 2379)
- **Worker LB**: Ingress 트래픽 (포트 80, 443)

---

## 사전 요구사항

### 필수 소프트웨어

- **Terraform**: v1.0 이상
- **SSH 클라이언트**: 서버 접근용
- **kubectl**: Kubernetes 클러스터 관리용 (선택사항)

### Kakao Cloud 준비사항

1. **Kakao Cloud 계정**
2. **Application Credential** 생성:
   ```
   - IAM > Application Credentials에서 생성
   - ID와 Secret 저장
   ```

3. **SSH KeyPair** 생성:
   ```
   - Compute > Key Pairs에서 생성
   - 이름: KPAAS_KEYPAIR
   - PEM 파일 다운로드 및 저장
   ```

4. **할당량 확인**:
   - Instance: 최소 6개
   - vCPU: 최소 24개
   - Memory: 최소 96GB
   - Volume: 최소 1.2TB
   - Public IP: 최소 8개
   - Load Balancer: 2개

---

## 배포된 리소스

### 현재 배포된 구성

#### Network Resources
| 리소스 타입 | 이름 | CIDR/주소 | ID |
|------------|------|-----------|-----|
| VPC | test-kpaas | 172.16.0.0/16 | abe85940-b9ca-4a1c-badc-3c7f3c259292 |
| Subnet | main_subnet | 172.16.0.0/24 | a2a91e45-c2c6-4ea7-be69-693dae9d0f0a |
| Security Group | kpaas-security-group | - | e93649b5-4408-4bf0-b77d-378b4e3b0aa5 |

#### Compute Resources
| 노드 타입 | 개수 | Private IP | Public IP | Instance ID |
|----------|------|------------|-----------|-------------|
| Master-1 | 1 | 172.16.0.192 | <Public IP> | 4bbf45d5-683f-49ef-84d4-efb405a8f74e |
| Master-2 | 1 | 172.16.0.157 | <Public IP>98 | 6c8b403d-9859-46ff-82ba-94cf2a6f52da |
| Master-3 | 1 | 172.16.0.254 | <Public IP> | 3e9b3cb0-af39-46ca-b0ef-0f755730df49 |
| Worker-1 | 1 | 172.16.0.12 | <Public IP> | bc78bcb1-a9a2-492d-8f9b-af8943c9833c |
| Worker-2 | 1 | 172.16.0.78 | <Public IP> | 3af122cd-902b-4132-aea7-981a0079959c |
| Worker-3 | 1 | 172.16.0.30 | <Public IP> | 5463bb52-45a2-4d88-92d3-2e0c8d5f3e8b |

**인스턴스 스펙**: t1i.xlarge (vCPU: 4, Memory: 16GB, Storage: 200GB)

#### Load Balancer Resources
| LB 타입 | Public IP | VIP | LB ID |
|---------|-----------|-----|-------|
| Master LB | <Public IP> | 172.16.0.176 | f516c85f-44a5-4f6f-835d-551804c39af1 |
| Worker LB | <Public IP> | 172.16.0.53 | 685bcf56-7e4e-4d6e-89d9-4111871578be |

---

## 디렉토리 구조

```
test2/
├── README.md                    # 이 문서
├── ARCHITECTURE.md              # 상세 아키텍처 문서
├── main.tf                      # 메인 Terraform 설정
├── variables.tf                 # 변수 정의
├── outputs.tf                   # 출력 정의
├── terraform.tfvars             # 변수 값 (Credential 포함 - .gitignore 필수)
├── provider.tf                  # Provider 설정
├── cloud-init.yaml              # 인스턴스 초기화 스크립트
├── KPAAS_KEYPAIR.pem           # SSH 키 (보안 주의!)
│
├── modules/                     # Terraform 모듈
│   ├── network/                # VPC, Subnet 생성
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── security/               # Security Group 생성
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── compute/                # Master, Worker 인스턴스
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── loadbalancer/           # Master, Worker LB
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── provisioner/            # K-PaaS 설치 자동화
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
│
└── generated/                   # 자동 생성된 스크립트
    ├── cp-cluster-vars.sh      # Kubespray 변수
    ├── 00.global_variable.sh   # 글로벌 변수
    ├── 01.all_common_setting.sh
    ├── 03.master_nfs_server.sh
    ├── 04.master_ssh_setting.sh
    ├── 05.master_install_k-pass.sh
    └── 06.master_install_k-pass_portal.sh
```

---

## 빠른 시작

### 1. 리포지토리 클론 및 이동

```bash
cd /Users/m/Documents/IdeaProjects/k-paas/csp/kakao-cloud/test2
```

### 2. Terraform 변수 설정

`terraform.tfvars` 파일을 편집하여 Kakao Cloud credential과 설정을 입력합니다:

```hcl
# Kakao Cloud Credentials
application_credential_id     = "your-credential-id"
application_credential_secret = "your-credential-secret"

# SSH Key
key_name     = "KPAAS_KEYPAIR"
ssh_key_path = "./KPAAS_KEYPAIR.pem"

# 나머지는 기본값 사용 가능
```

### 3. SSH 키 배치

```bash
# Kakao Cloud에서 다운로드한 PEM 파일을 프로젝트 디렉토리에 복사
cp ~/Downloads/KPAAS_KEYPAIR.pem ./
chmod 400 ./KPAAS_KEYPAIR.pem
```

### 4. Terraform 초기화 및 배포

```bash
# Terraform 초기화
terraform init

# 계획 확인
terraform plan

# 배포 실행 (약 30-40분 소요)
terraform apply -auto-approve
```

### 5. 배포 상태 확인

```bash
# 출력 정보 확인
terraform output

# Master-1에 SSH 접속하여 설치 로그 확인
ssh -i ./KPAAS_KEYPAIR.pem ubuntu@$(terraform output -raw provisioner_status | jq -r '.master1_public_ip')
tail -f /home/ubuntu/kpaas_install.log
```

---

## 설정 가이드

### terraform.tfvars 주요 설정

```hcl
#####################################################################
# Network Configuration
#####################################################################
vpc_name                = "test-kpaas"          # VPC 이름
vpc_cidr                = "172.16.0.0/16"       # VPC CIDR
subnet_cidr             = "172.16.0.0/24"       # Subnet CIDR
availability_zone       = "kr-central-2-a"      # 가용 영역

#####################################################################
# Compute Configuration
#####################################################################
master_count     = 3                     # Master 노드 개수 (HA를 위해 3개 권장)
worker_count     = 3                     # Worker 노드 개수
image_name       = "Ubuntu 24.04"        # OS 이미지
instance_flavor  = "t1i.xlarge"          # 인스턴스 타입 (vCPU:4, Memory:16GB)
volume_size      = 200                   # 디스크 크기 (GB)

#####################################################################
# K-PaaS Configuration
#####################################################################
metallb_ip_range     = "172.16.0.210-172.16.0.250"  # MetalLB IP 풀
ingress_nginx_ip     = "172.16.0.201"                # Ingress Nginx LB IP
portal_domain        = "k-paas.io"                   # 포털 도메인
auto_install_kpaas   = true                          # 자동 설치 활성화
```

### 인스턴스 타입 선택 가이드

| 타입 | vCPU | Memory | 용도 | 권장 |
|------|------|--------|------|------|
| t1i.large | 2 | 8GB | 개발/테스트 | ❌ (최소 사양 미달) |
| t1i.xlarge | 4 | 16GB | 소규모 운영 | ✅ (현재 사용) |
| t1i.2xlarge | 8 | 32GB | 중규모 운영 | ✅ (권장) |
| t1i.4xlarge | 16 | 64GB | 대규모 운영 | ✅ |

---

## 배포 과정

### Terraform 실행 단계

1. **Module: Network** (약 2분)
   - VPC 생성
   - Subnet 생성

2. **Module: Security** (약 1분)
   - Security Group 생성
   - 방화벽 규칙 설정

3. **Module: Compute** (약 5분)
   - Master 인스턴스 3개 생성
   - Worker 인스턴스 3개 생성
   - Public IP 할당
   - cloud-init 실행

4. **Module: LoadBalancer** (약 5분)
   - Master LB 생성 및 설정
   - Worker LB 생성 및 설정
   - Target Group 구성
   - Health Check 설정

5. **Module: Provisioner** (약 30-40분)
   - SSH 설정 및 호스트 등록
   - NFS 서버 설정
   - Kubespray를 통한 Kubernetes 클러스터 구축
   - K-PaaS 컴포넌트 설치
   - CP-Portal 설치

### 자동 설치 프로세스

Provisioner 모듈이 Master-1 노드에서 다음 스크립트를 순차적으로 실행합니다:

1. **00.global_variable.sh**: 글로벌 환경 변수 설정
2. **01.all_common_setting.sh**: 모든 노드 공통 설정
3. **03.master_nfs_server.sh**: NFS 서버 설정
4. **04.master_ssh_setting.sh**: SSH 키 배포 및 설정
5. **05.master_install_k-pass.sh**: K-PaaS 클러스터 설치
6. **06.master_install_k-pass_portal.sh**: CP-Portal 설치

---

## 배포 후 작업

### 1. 클러스터 상태 확인

```bash
# Master-1에 SSH 접속
ssh -i ./KPAAS_KEYPAIR.pem ubuntu@<Public IP>

# 노드 상태 확인
kubectl get nodes

# 모든 Pod 상태 확인
kubectl get pods -A

# 네임스페이스 확인
kubectl get ns
```

### 2. 외부에서 kubectl 접근 설정

```bash
# Kubeconfig 파일 다운로드
scp -i ./KPAAS_KEYPAIR.pem ubuntu@<Public IP>:/home/ubuntu/.kube/config ./kubeconfig

# Kubeconfig 설정
export KUBECONFIG=$(pwd)/kubeconfig

# 클러스터 접근 테스트
kubectl cluster-info
kubectl get nodes
```

### 3. /etc/hosts 설정 (로컬 머신)

서비스 접근을 위해 로컬 머신의 `/etc/hosts`에 다음을 추가:

```bash
# K-PaaS Services
<Public IP> k-paas.io portal.k-paas.io harbor.k-paas.io keycloak.k-paas.io openbao.k-paas.io chartmuseum.k-paas.io
<Public IP> cluster-endpoint
```

### 4. 포스트 설치 스크립트 실행

배포 후 필요한 추가 설정을 위해 포스트 설치 스크립트를 실행합니다:

```bash
# Master-1에서 실행
cd /home/ubuntu/scripts
bash 10.post_install_fixes.sh
```

이 스크립트는 다음을 수행합니다:
- Harbor 인증서 설정
- Pod DNS 해결
- API 서버 인증서 재생성 (외부 접근용)

자세한 내용은 `/scripts/README_POST_INSTALL_FIXES.md`를 참조하세요.

---

## 접속 정보

### Kubernetes API Server

**외부 접근** (로컬 머신에서):
```bash
# API Server
https://<Public IP>:6443

# kubectl 사용
export KUBECONFIG=./kubeconfig
kubectl get nodes
```

**내부 접근** (클러스터 노드에서):
```bash
# API Server
https://172.16.0.176:6443

# kubectl 사용
kubectl get nodes
```

### K-PaaS Services

모든 서비스는 Worker LB (<Public IP>)를 통해 접근합니다:

| 서비스 | URL | 기본 계정 |
|--------|-----|-----------|
| **CP-Portal** | https://portal.k-paas.io | admin / 설치 로그 참조 |
| **Harbor** | https://harbor.k-paas.io | admin / 설치 로그 참조 |
| **Keycloak** | https://keycloak.k-paas.io | admin / 설치 로그 참조 |
| **OpenBao** | https://openbao.k-paas.io | Root token: 설치 로그 참조 |

### SSH 접속

**Master 노드**:
```bash
# Master-1
ssh -i ./KPAAS_KEYPAIR.pem ubuntu@<Public IP>

# Master-2
ssh -i ./KPAAS_KEYPAIR.pem ubuntu@<Public IP>98

# Master-3
ssh -i ./KPAAS_KEYPAIR.pem ubuntu@<Public IP>
```

**Worker 노드**:
```bash
# Worker-1
ssh -i ./KPAAS_KEYPAIR.pem ubuntu@<Public IP>

# Worker-2
ssh -i ./KPAAS_KEYPAIR.pem ubuntu@<Public IP>

# Worker-3
ssh -i ./KPAAS_KEYPAIR.pem ubuntu@<Public IP>
```

---

## 문제 해결

### 일반적인 문제

#### 1. Terraform apply 실패

**문제**: Provider 인증 오류
```
Error: Failed to authenticate with Kakao Cloud
```

**해결**:
```bash
# terraform.tfvars에서 credential 확인
# Kakao Cloud IAM에서 Application Credential 재생성
```

---

#### 2. K-PaaS 설치 진행 상황 확인

**로그 확인**:
```bash
# Master-1에 SSH 접속
ssh -i ./KPAAS_KEYPAIR.pem ubuntu@<Public IP>

# 전체 설치 로그
tail -f /home/ubuntu/kpaas_install.log

# Kubernetes 클러스터 설치 로그
tail -f /home/ubuntu/cp-deployment/standalone/cluster-install.log

# Portal 설치 로그
tail -f /home/ubuntu/workspace/container-platform/cp-portal-deployment/script/deploy-portal-result.log
```

---

### 디버깅 명령어

```bash
# 노드 상태 확인
kubectl get nodes -o wide

# Pod 상태 확인
kubectl get pods -A -o wide

# 특정 Pod 로그 확인
kubectl logs -n <namespace> <pod-name>

# Pod 이벤트 확인
kubectl describe pod -n <namespace> <pod-name>

# 서비스 확인
kubectl get svc -A

# Ingress 확인
kubectl get ingress -A

# PV/PVC 확인
kubectl get pv,pvc -A
```

---

## 리소스 정리

### 전체 인프라 삭제

```bash
# Terraform으로 생성된 모든 리소스 삭제
terraform destroy -auto-approve
```

**주의사항**:
- 삭제 전 중요 데이터는 반드시 백업하세요
- 삭제 후 복구가 불가능합니다
- Public IP는 즉시 해제되어 재사용할 수 없습니다

### 선택적 리소스 삭제

특정 리소스만 삭제하려면:

```bash
# 특정 리소스 삭제
terraform destroy -target=module.worker

# Worker 노드만 삭제
terraform destroy -target=module.compute.kakaocloud_instance.worker

# 확인 후 삭제
terraform destroy
```

---

## 추가 문서

- **[ARCHITECTURE.md](./ARCHITECTURE.md)**: 상세 아키텍처 및 설계 문서
- **[scripts/README_POST_INSTALL_FIXES.md](../../../scripts/README_POST_INSTALL_FIXES.md)**: 포스트 설치 수정 가이드
- **[scripts/SCRIPT_TEMPLATES.md](../../../scripts/SCRIPT_TEMPLATES.md)**: 스크립트 템플릿
- **[scripts/POST_INSTALL_FIXES_SUMMARY.md](../../../scripts/POST_INSTALL_FIXES_SUMMARY.md)**: 포스트 설치 요약

---

## 버전 정보

- **Terraform**: >= 1.0
- **Provider**: kakaocloud v0.1.4
- **K-PaaS**: 1.6.2
- **Kubernetes**: v1.32.5
- **CRI-O**: v1.32.x
- **Ubuntu**: 24.04 LTS

---

## 지원

문제가 발생하거나 질문이 있으시면:
1. 이슈 트래커에 등록
2. 문서 확인: README.md, ARCHITECTURE.md
3. 로그 확인: `/home/ubuntu/kpaas_install.log`
