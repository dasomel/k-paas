# K-PaaS 설치 요구사항 (Prerequisite)

## 인스턴스 구성

| 인스턴스 종류 | 인스턴스 개수 | 비고 |
|--------------|-------------|------|
| Control Plane | 3개 (권장) | 고가용성을 위해 3개 권장, 테스트 환경에서는 1개 가능 |
| Worker | 3개 이상 | NFS 스토리지 사용 시 1개 이상, Rook-Ceph 사용 시 3개 이상 |
| Load Balancer | 2개 | Master LB (API Server), Worker LB (Ingress) |

## 하드웨어 요구사항

### Master 노드 (Control Plane)

| 항목 | 권장 사양 | 최소 사양 |
|------|----------|----------|
| CPU | 4 vCPU | 2 vCPU |
| Memory | 16GB | 8GB |
| Disk | 100GB | 50GB |

### Worker 노드

| 항목 | 권장 사양 | 최소 사양 |
|------|----------|----------|
| CPU | 8 vCPU | 4 vCPU |
| Memory | 32GB | 16GB |
| Disk | 200GB | 100GB |

## Kakao Cloud 인스턴스 타입 권장

| 노드 타입 | 인스턴스 타입 | vCPU | Memory | 권장 |
|----------|-------------|------|--------|------|
| Master | t1i.large | 2 | 8GB | 최소 사양 |
| Master | t1i.xlarge | 4 | 16GB | **권장** |
| Worker | t1i.xlarge | 4 | 16GB | 최소 사양 |
| Worker | t1i.2xlarge | 8 | 32GB | **권장** |

## 소프트웨어 요구사항

- **OS**: Ubuntu 24.04 LTS (deb 호환 Linux)
- **Kubernetes**: v1.33.5
- **Container Runtime**: CRI-O v1.33.5
- **Python**: 3.x (Ansible 실행용)

## 네트워크 요구사항

- 클러스터의 모든 노드 간 완전한 네트워크 연결
- 인터넷 접근 가능 (패키지 설치용)
- 필수 포트:
  - 6443: Kubernetes API Server
  - 2379-2380: etcd
  - 10250-10252: Kubelet
  - 30000-32767: NodePort 범위
  - 80, 443: Ingress

## Kakao Cloud 할당량 확인

배포 전 다음 리소스 할당량을 확인하세요:

| 리소스 | 필요량 |
|--------|--------|
| Instance | 6개 이상 |
| vCPU | 24개 이상 |
| Memory | 96GB 이상 |
| Volume | 1.2TB 이상 |
| Public IP | 8개 이상 |
| Load Balancer | 2개 |

## 사전 준비

1. **Kakao Cloud 계정** 생성
2. **Application Credential** 생성 (IAM > Application Credentials)
3. **SSH KeyPair** 생성 (Compute > Key Pairs)
4. **Terraform** 설치 (v1.0 이상)
