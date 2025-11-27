# K-PaaS on Kakao Cloud - Architecture Documentation

K-PaaS 클러스터의 상세 아키텍처, 네트워크 구성, 컴포넌트 관계, 그리고 보안 설정에 대한 기술 문서입니다.

## 목차

- [개요](#개요)
- [전체 아키텍처](#전체-아키텍처)
- [네트워크 아키텍처](#네트워크-아키텍처)
- [컴퓨팅 아키텍처](#컴퓨팅-아키텍처)
- [스토리지 아키텍처](#스토리지-아키텍처)
- [보안 아키텍처](#보안-아키텍처)
- [고가용성 및 이중화](#고가용성-및-이중화)
- [서비스 아키텍처](#서비스-아키텍처)
- [데이터 흐름](#데이터-흐름)
- [확장성 고려사항](#확장성-고려사항)

---

## 개요

### 시스템 구성 요약

```
┌─────────────────────────────────────────────────────────────────┐
│                        K-PaaS Platform                          │
│                                                                  │
│  ┌────────────────┐              ┌──────────────────┐          │
│  │  Control Plane │              │  Worker Nodes    │          │
│  │  (3 Masters)   │◄────────────►│  (3 Workers)     │          │
│  │  - API Server  │              │  - Pods/Apps     │          │
│  │  - etcd        │              │  - CRI-O         │          │
│  │  - Scheduler   │              │  - Kubelet       │          │
│  └────────────────┘              └──────────────────┘          │
│          ▲                                ▲                      │
│          │                                │                      │
│    ┌─────┴───────┐              ┌────────┴────────┐            │
│    │  Master LB  │              │   Worker LB     │            │
│    │ (NLB L4)    │              │   (NLB L4)      │            │
│    └─────────────┘              └─────────────────┘            │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
                              │
                         Internet
                              │
                         Users/APIs
```

### 핵심 사양

| 구분 | 사양 |
|------|------|
| **클라우드** | Kakao Cloud (kr-central-2-a) |
| **Kubernetes** | v1.32.5 |
| **K-PaaS** | v1.6.2 |
| **컨테이너 런타임** | CRI-O v1.32.x |
| **CNI** | Calico |
| **CSI** | NFS Provisioner |
| **Ingress** | Nginx Ingress Controller |
| **Load Balancer** | MetalLB + Kakao NLB |

---

## 전체 아키텍처

### 레이어별 구성

```
┌──────────────────────────────────────────────────────────────────┐
│                      Application Layer                           │
│  - CP-Portal (Management Console)                               │
│  - Harbor (Container Registry)                                   │
│  - Keycloak (Identity & Access Management)                      │
│  - OpenBao (Secrets Management)                                 │
└──────────────────────────────────────────────────────────────────┘
                              ▲
                              │
┌──────────────────────────────────────────────────────────────────┐
│                     Kubernetes Layer                             │
│  - API Server (HA with 3 masters)                               │
│  - etcd (Distributed key-value store)                           │
│  - Controller Manager                                            │
│  - Scheduler                                                     │
│  - Kubelet (on all nodes)                                       │
└──────────────────────────────────────────────────────────────────┘
                              ▲
                              │
┌──────────────────────────────────────────────────────────────────┐
│                     Container Layer                              │
│  - CRI-O Runtime                                                │
│  - Pods & Containers                                            │
│  - CNI (Calico)                                                 │
└──────────────────────────────────────────────────────────────────┘
                              ▲
                              │
┌──────────────────────────────────────────────────────────────────┐
│                   Infrastructure Layer                           │
│  - VM Instances (Kakao Cloud)                                   │
│  - Network Load Balancers                                        │
│  - VPC & Subnet                                                  │
│  - Security Groups                                               │
│  - Storage Volumes                                               │
└──────────────────────────────────────────────────────────────────┘
```

---

## 네트워크 아키텍처

### VPC 및 서브넷 구성

```
VPC: test-kpaas (172.16.0.0/16)
│
├── Subnet: main_subnet (172.16.0.0/24)
│   │
│   ├── Master Nodes
│   │   ├── master-1: 172.16.0.192
│   │   ├── master-2: 172.16.0.157
│   │   └── master-3: 172.16.0.254
│   │
│   ├── Worker Nodes
│   │   ├── worker-1: 172.16.0.12
│   │   ├── worker-2: 172.16.0.78
│   │   └── worker-3: 172.16.0.30
│   │
│   ├── Load Balancers (VIP)
│   │   ├── Master LB: 172.16.0.176
│   │   └── Worker LB: 172.16.0.53
│   │
│   └── Service IP Ranges
│       ├── Kubernetes Services: 10.233.0.0/18
│       ├── Pod Network: 10.233.64.0/18
│       ├── MetalLB Pool: 172.16.0.210-172.16.0.250
│       └── Ingress Nginx LB: 172.16.0.201
│
└── Default Subnet (172.16.255.0/24)
    └── Reserved for future use
```

### 외부 IP 할당

| 용도 | Private IP | Public IP | 포트 |
|------|-----------|-----------|------|
| **Master LB** | 172.16.0.176 | <Public IP> | 6443, 2379 |
| **Worker LB** | 172.16.0.53 | <Public IP> | 80, 443 |
| **Master-1** | 172.16.0.192 | <Public IP> | 22 |
| **Master-2** | 172.16.0.157 | <Public IP> | 22 |
| **Master-3** | 172.16.0.254 | <Public IP> | 22 |
| **Worker-1** | 172.16.0.12 | <Public IP> | 22 |
| **Worker-2** | 172.16.0.78 | <Public IP>| 22 |
| **Worker-3** | 172.16.0.30 | <Public IP> | 22 |

### 네트워크 플로우

#### 외부 → Kubernetes API Server

```
User/Client (kubectl)
      │
      │ HTTPS (TLS)
      ▼
Master LB Public IP (<Public IP>:6443)
      │
      │ TCP
      ▼
Master LB VIP (172.16.0.176:6443)
      │
      ├──► Master-1 (172.16.0.192:6443)
      ├──► Master-2 (172.16.0.157:6443)
      └──► Master-3 (172.16.0.254:6443)
```

#### 외부 → 애플리케이션 서비스

```
User/Browser
      │
      │ HTTP/HTTPS
      ▼
Worker LB Public IP (<Public IP>:80/443)
      │
      │ TCP
      ▼
Worker LB VIP (172.16.0.53:80/443)
      │
      ├──► Worker-1 NodePort (172.16.0.12:31080/31443)
      ├──► Worker-2 NodePort (172.16.0.78:31080/31443)
      └──► Worker-3 NodePort (172.16.0.30:31080/31443)
            │
            │ Ingress Controller
            ▼
       Service (ClusterIP)
            │
            ▼
         Pod (Application)
```

### DNS 구성

#### 클러스터 내부 DNS (CoreDNS)

```
CoreDNS Service: 10.233.0.3:53
├── kubernetes.default.svc.cluster.local → 10.233.0.1
├── *.svc.cluster.local → Service Discovery
└── Forward to upstream (8.8.8.8, 8.8.4.4)
```

#### 외부 DNS (수동 설정 필요)

```
/etc/hosts 또는 DNS Server:
<Public IP>  k-paas.io
<Public IP>  portal.k-paas.io
<Public IP>  harbor.k-paas.io
<Public IP>  keycloak.k-paas.io
<Public IP>  openbao.k-paas.io
<Public IP>  chartmuseum.k-paas.io
<Public IP> cluster-endpoint
```

---

## 컴퓨팅 아키텍처

### Master Node 구성

**역할**: Kubernetes Control Plane 호스팅

```
Master Node (x3 for HA)
├── OS: Ubuntu 24.04 LTS
├── Instance Type: t1i.xlarge (vCPU: 4, Memory: 16GB)
├── Storage: 200GB SSD
│
├── Kubernetes Components
│   ├── kube-apiserver (Port: 6443)
│   ├── kube-controller-manager
│   ├── kube-scheduler
│   ├── etcd (Port: 2379, 2380)
│   └── kubelet
│
├── Network Components
│   ├── calico-node (CNI)
│   ├── kube-proxy
│   └── CoreDNS (replica)
│
└── Additional Services
    ├── NFS Server (Master-1 only)
    │   └── /home/share → /data
    └── SSH Server (Port: 22)
```

### Worker Node 구성

**역할**: 애플리케이션 워크로드 실행

```
Worker Node (x3)
├── OS: Ubuntu 24.04 LTS
├── Instance Type: t1i.xlarge (vCPU: 4, Memory: 16GB)
├── Storage: 200GB SSD
│
├── Kubernetes Components
│   ├── kubelet
│   └── kube-proxy
│
├── Container Runtime
│   └── CRI-O v1.32.x
│       ├── Container Images
│       ├── Container Networks
│       └── Container Storage
│
├── Network Components
│   ├── calico-node (CNI)
│   ├── MetalLB Speaker
│   └── Ingress Nginx Controller (NodePort: 31080, 31443)
│
└── Additional Services
    ├── NFS Client (mounts /data from Master-1)
    └── SSH Server (Port: 22)
```

### 리소스 할당

| 노드 타입 | vCPU | Memory | Storage | Network |
|----------|------|--------|---------|---------|
| Master-1 | 4 | 16GB | 200GB | 10Gbps |
| Master-2 | 4 | 16GB | 200GB | 10Gbps |
| Master-3 | 4 | 16GB | 200GB | 10Gbps |
| Worker-1 | 4 | 16GB | 200GB | 10Gbps |
| Worker-2 | 4 | 16GB | 200GB | 10Gbps |
| Worker-3 | 4 | 16GB | 200GB | 10Gbps |
| **Total** | **24** | **96GB** | **1.2TB** | - |

---

## 스토리지 아키텍처

### 스토리지 계층

```
┌─────────────────────────────────────────────────────────────┐
│                    Persistent Volumes                        │
│                                                              │
│  PVC (Applications) ──► PV ──► NFS ──► Master-1:/data      │
│                                                              │
│  - Database Volumes                                         │
│  - Application Data                                         │
│  - Shared Configurations                                    │
└─────────────────────────────────────────────────────────────┘
                           ▲
                           │
┌─────────────────────────────────────────────────────────────┐
│                  Storage Class (NFS)                        │
│                                                              │
│  - Provisioner: nfs-subdir-external-provisioner             │
│  - Reclaim Policy: Delete                                    │
│  - Access Mode: ReadWriteMany                               │
└─────────────────────────────────────────────────────────────┘
                           ▲
                           │
┌─────────────────────────────────────────────────────────────┐
│               NFS Server (Master-1)                         │
│                                                              │
│  Export: /data                                              │
│  Mount: /home/share                                         │
│  Permissions: 777 (no_root_squash)                          │
└─────────────────────────────────────────────────────────────┘
                           ▲
                           │
┌─────────────────────────────────────────────────────────────┐
│              Local Disk (Master-1)                          │
│                                                              │
│  /dev/vda: 200GB SSD                                        │
│  Filesystem: ext4                                           │
└─────────────────────────────────────────────────────────────┘
```

### NFS 구성

**서버**: Master-1 (172.16.0.192)

```bash
# NFS Export
/data    *(rw,sync,no_root_squash,no_subtree_check)

# Mount Point
/home/share → /data

# Permissions
drwxrwxrwx root:root /data
```

**클라이언트**: All Worker Nodes

```bash
# Mount
172.16.0.192:/data  /data  nfs  defaults  0 0

# Usage
- Container persistent volumes
- Shared configuration files
- Application data storage
```

### 스토리지 사용 예시

| 애플리케이션 | PVC | Size | Access Mode | Path |
|-------------|-----|------|-------------|------|
| Harbor Registry | harbor-pvc | 20Gi | RWX | /data/harbor |
| PostgreSQL (Harbor) | db-pvc | 10Gi | RWO | /data/postgres |
| Keycloak DB | keycloak-db-pvc | 5Gi | RWO | /data/keycloak |
| OpenBao Data | openbao-pvc | 5Gi | RWX | /data/openbao |

---

## 보안 아키텍처

### Security Group 규칙

**Ingress Rules** (모든 노드 공통):

| 프로토콜 | 포트 범위 | 소스 | 용도 |
|---------|----------|------|------|
| TCP | 22 | 0.0.0.0/0 | SSH 접속 |
| TCP | 6443 | 0.0.0.0/0 | Kubernetes API |
| TCP | 2379-2380 | 172.16.0.0/16 | etcd |
| TCP | 10250 | 172.16.0.0/16 | Kubelet API |
| TCP | 10251 | 172.16.0.0/16 | kube-scheduler |
| TCP | 10252 | 172.16.0.0/16 | kube-controller-manager |
| TCP | 10255 | 172.16.0.0/16 | Read-only Kubelet API |
| TCP | 30000-32767 | 0.0.0.0/0 | NodePort Services |
| UDP | 8472 | 172.16.0.0/16 | VXLAN (Calico) |
| TCP | 9099 | 172.16.0.0/16 | Calico BGP |
| TCP | 179 | 172.16.0.0/16 | Calico BGP |
| TCP | 5473 | 172.16.0.0/16 | Calico Typha |
| TCP | 80, 443 | 0.0.0.0/0 | HTTP/HTTPS |
| TCP | 2049 | 172.16.0.0/16 | NFS |
| ICMP | All | 172.16.0.0/16 | Ping |

**Egress Rules**:

| 프로토콜 | 포트 범위 | 대상 | 용도 |
|---------|----------|------|------|
| All | All | 0.0.0.0/0 | 모든 외부 통신 허용 |

### TLS/SSL 인증서

#### 1. Kubernetes 내부 인증서

```
Certificate Authority (CA)
├── /etc/kubernetes/ssl/ca.crt
└── /etc/kubernetes/ssl/ca.key

API Server Certificate
├── /etc/kubernetes/ssl/apiserver.crt
├── /etc/kubernetes/ssl/apiserver.key
└── Subject Alternative Names:
    ├── DNS: kubernetes, kubernetes.default, *.svc.cluster.local
    ├── IP: 10.233.0.1 (Kubernetes Service)
    ├── IP: 172.16.0.192, 172.16.0.157, 172.16.0.254 (Masters)
    ├── IP: 172.16.0.176 (Master LB VIP)
    └── IP: <Public IP> (Master LB Public)

etcd Certificate
├── /etc/kubernetes/ssl/etcd/server.crt
└── /etc/kubernetes/ssl/etcd/server.key

Kubelet Certificates (per node)
├── /var/lib/kubelet/pki/kubelet-client-current.pem
└── /var/lib/kubelet/pki/kubelet.crt
```

#### 2. 애플리케이션 인증서 (Self-Signed)

```
Harbor
├── harbor.k-paas.io.crt
└── harbor.k-paas.io.key

Keycloak
├── keycloak.k-paas.io.crt
└── keycloak.k-paas.io.key

Portal
├── portal.k-paas.io.crt
└── portal.k-paas.io.key
```

### 인증 및 인가

#### Kubernetes RBAC

```
Service Accounts
├── system:masters (Cluster Admin)
├── system:nodes (Kubelet)
├── system:kube-controller-manager
├── system:kube-scheduler
└── Custom Service Accounts (per namespace)

Cluster Roles
├── cluster-admin (Full access)
├── admin (Namespace admin)
├── edit (Resource modification)
└── view (Read-only)

Role Bindings
├── ClusterRoleBinding (cluster-wide)
└── RoleBinding (namespace-scoped)
```

#### Keycloak IAM

```
Realm: k-paas
├── Users
├── Groups
├── Roles
└── Clients
    ├── portal-client
    ├── harbor-client
    └── kubernetes-client
```

---

## 고가용성 및 이중화

### Control Plane HA

```
                   Clients
                      │
                      ▼
              Master Load Balancer
            (Health Check: /healthz)
                      │
        ┌─────────────┼─────────────┐
        │             │             │
        ▼             ▼             ▼
   Master-1      Master-2      Master-3
 (172.16.0.192)(172.16.0.157)(172.16.0.254)
        │             │             │
        └─────────────┼─────────────┘
                      │
                   etcd Cluster
              (Leader Election)
```

**특징**:
- **Active-Active**: 모든 마스터 노드가 동시에 활성 상태
- **Leader Election**: etcd가 Raft 알고리즘으로 리더 선출
- **자동 장애 조치**: LB Health Check를 통한 장애 감지 및 제외

### etcd Quorum

```
3-node etcd cluster
├── Quorum: 2 nodes (N/2 + 1)
├── Fault Tolerance: 1 node failure
└── Data Replication: All nodes
```

**장애 시나리오**:
- **1개 노드 다운**: 클러스터 정상 동작 (Quorum 유지)
- **2개 노드 다운**: 클러스터 Read-Only (Quorum 상실)
- **3개 노드 다운**: 클러스터 완전 정지

### Worker Node HA

```
Worker Nodes (3개)
├── Pod 분산 배치 (Deployment)
├── Service 로드 밸런싱 (kube-proxy)
└── Ingress 트래픽 분산 (Worker LB)
```

**Pod 배치 전략**:
- **AntiAffinity**: 같은 애플리케이션 Pod를 다른 노드에 배치
- **PodDisruptionBudget**: 최소 가용 Pod 수 보장
- **Node Affinity**: 특정 워크로드를 특정 노드에 배치

---

## 서비스 아키텍처

### K-PaaS 핵심 컴포넌트

```
┌────────────────────────────────────────────────────────────┐
│                     CP-Portal (Portal UI/API)              │
│  - User Management                                         │
│  - Resource Management                                      │
│  - Monitoring Dashboard                                     │
└────────────────────────────────────────────────────────────┘
                          │
                          │ REST API
                          ▼
┌────────────────────────────────────────────────────────────┐
│                   Kubernetes API Server                    │
└────────────────────────────────────────────────────────────┘
                          │
        ┌─────────────────┼─────────────────┐
        │                 │                 │
        ▼                 ▼                 ▼
┌──────────────┐  ┌─────────────┐  ┌─────────────┐
│   Harbor     │  │  Keycloak   │  │  OpenBao    │
│  (Registry)  │  │   (IAM)     │  │  (Secrets)  │
└──────────────┘  └─────────────┘  └─────────────┘
```

### Harbor (Container Registry)

```
Harbor Components
├── harbor-core (API & UI)
├── harbor-portal (Web UI)
├── harbor-registry (OCI Registry)
├── harbor-registryctl (Registry Controller)
├── harbor-jobservice (Background Jobs)
├── harbor-chartmuseum (Helm Charts)
├── harbor-notary (Image Signing)
└── harbor-database (PostgreSQL)

Storage
└── NFS: /data/harbor
    ├── /registry (Container Images)
    └── /charts (Helm Charts)

Access
├── Internal: harbor.k-paas.io
└── External: https://<Public IP> (via Worker LB)
```

### Keycloak (Identity & Access Management)

```
Keycloak Components
├── keycloak-server (SSO Server)
└── keycloak-database (PostgreSQL)

Configuration
├── Realm: k-paas
├── Clients: portal, harbor, kubernetes
├── Users: Admin, Developers, Operators
└── Roles: RBAC roles mapping

Integration
├── CP-Portal → Keycloak (OAuth2/OIDC)
├── Harbor → Keycloak (OIDC)
└── Kubernetes → Keycloak (OIDC)

Access
├── Internal: keycloak.k-paas.io
└── External: https://<Public IP>/auth (via Worker LB)
```

### OpenBao (Secrets Management)

```
OpenBao Components
├── openbao-server (Vault Server)
└── openbao-storage (Persistent Storage)

Secrets Engine
├── KV v2 (Key-Value Secrets)
├── Database (Dynamic DB Credentials)
└── PKI (Certificate Management)

Integration
├── Kubernetes → OpenBao (Service Account)
├── Applications → OpenBao (Sidecar Injection)
└── CI/CD → OpenBao (API Access)

Access
├── Internal: openbao.k-paas.io
└── External: https://<Public IP>/openbao (via Worker LB)
```

### MetalLB (Load Balancer)

```
MetalLB Configuration
├── Mode: Layer 2 (ARP)
├── IP Pool: 172.16.0.210-172.16.0.250
└── Speakers: Running on all worker nodes

Service Types
├── LoadBalancer → MetalLB assigns IP from pool
├── ClusterIP → Internal only
└── NodePort → Exposed on all nodes

Example Services
├── ingress-nginx-controller: 172.16.0.201
├── harbor-service: 172.16.0.210
└── portal-service: 172.16.0.211
```

### Ingress Nginx Controller

```
Ingress Architecture
┌─────────────────────────────────────────────┐
│          Worker Load Balancer               │
│       (<Public IP>:80/443)                │
└─────────────────────────────────────────────┘
                   │
        ┌──────────┼──────────┐
        │          │          │
        ▼          ▼          ▼
  Worker-1    Worker-2    Worker-3
 (NodePort   (NodePort   (NodePort
  31080/     31080/      31080/
  31443)     31443)      31443)
        │          │          │
        └──────────┼──────────┘
                   │
                   ▼
        Ingress Nginx Controller
        (MetalLB: 172.16.0.201)
                   │
        ┌──────────┼──────────┐
        │          │          │
        ▼          ▼          ▼
    Harbor    Keycloak   Portal
   Service    Service    Service

Ingress Rules
├── harbor.k-paas.io → harbor-service:80
├── keycloak.k-paas.io → keycloak-service:8080
├── portal.k-paas.io → portal-service:8080
└── openbao.k-paas.io → openbao-service:8200
```

---

## 데이터 흐름

### 사용자 접근 플로우

#### 1. Portal 접근

```
User (Browser)
    │
    │ 1. HTTPS Request (https://portal.k-paas.io)
    ▼
DNS Resolution (<Public IP>)
    │
    │ 2. TCP Connection
    ▼
Worker Load Balancer (<Public IP>:443)
    │
    │ 3. Distribute to NodePort
    ▼
Worker Nodes (31443)
    │
    │ 4. Forward to Ingress Controller
    ▼
Ingress Nginx Controller (172.16.0.201)
    │
    │ 5. Route based on hostname
    ▼
Portal Service (ClusterIP)
    │
    │ 6. Load balance to Pods
    ▼
Portal Pod (Application)
    │
    │ 7. Authenticate with Keycloak
    ▼
Keycloak Service
    │
    │ 8. Return Token
    ▼
Portal Pod
    │
    │ 9. API Call to K8s
    ▼
Kubernetes API Server (via Service Account)
    │
    │ 10. Return Resources
    ▼
Portal Pod → User
```

#### 2. Container Image Push/Pull

```
Developer (Docker CLI)
    │
    │ 1. docker push harbor.k-paas.io/project/image:tag
    ▼
DNS Resolution (<Public IP>)
    │
    │ 2. TLS Handshake
    ▼
Worker Load Balancer (<Public IP>:443)
    │
    │ 3. Forward to NodePort
    ▼
Ingress Nginx Controller
    │
    │ 4. Route to Harbor
    ▼
Harbor Registry Service
    │
    │ 5. Authenticate (Keycloak/local)
    ▼
Harbor Registry Pod
    │
    │ 6. Store image layers
    ▼
NFS Storage (/data/harbor/registry)
    │
    │ 7. Return success
    ▼
Developer
```

### 클러스터 내부 통신

#### Pod → Pod (Same Node)

```
Pod A (172.16.0.12)
    │
    │ 1. IP Packet to Pod B
    ▼
CNI Bridge (cali-xxx)
    │
    │ 2. Direct routing (same node)
    ▼
Pod B (172.16.0.12)
```

#### Pod → Pod (Different Node)

```
Pod A (Worker-1: 10.233.64.5)
    │
    │ 1. IP Packet to Pod B
    ▼
Calico vRouter (Worker-1)
    │
    │ 2. VXLAN Tunnel
    ▼
Calico vRouter (Worker-2)
    │
    │ 3. Deliver to Pod
    ▼
Pod B (Worker-2: 10.233.65.10)
```

#### Pod → Service

```
Pod A
    │
    │ 1. DNS Query: harbor-service
    ▼
CoreDNS (10.233.0.3)
    │
    │ 2. Return ClusterIP: 10.233.10.50
    ▼
Pod A
    │
    │ 3. TCP Connection to 10.233.10.50:80
    ▼
kube-proxy (iptables rules)
    │
    │ 4. DNAT to backend Pod
    ▼
Harbor Pod (10.233.64.20:8080)
```

---

## 확장성 고려사항

### 수평 확장 (Horizontal Scaling)

#### Worker Node 추가

```bash
# 1. Terraform에서 worker_count 증가
worker_count = 4  # 3 → 4

# 2. Terraform apply
terraform apply

# 3. 자동으로 새 worker 노드가 클러스터에 join됨
```

#### Pod 확장 (Horizontal Pod Autoscaler)

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: portal-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: cp-portal-deployment
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

### 수직 확장 (Vertical Scaling)

#### Instance Type 변경

```hcl
# terraform.tfvars
instance_flavor = "t1i.2xlarge"  # xlarge → 2xlarge
# vCPU: 4 → 8, Memory: 16GB → 32GB
```

**절차**:
1. Worker 노드 Drain
2. Instance type 변경
3. Worker 노드 재시작
4. Uncordon 및 Pod 재배치

### 스토리지 확장

#### NFS 용량 증가

```bash
# Master-1에서 실행
sudo lvextend -L +100G /dev/vg0/lv_data
sudo resize2fs /dev/vg0/lv_data
```

#### 추가 스토리지 프로바이더 통합

- **Ceph RBD**: Block storage for databases
- **Rook**: Cloud-native storage orchestrator
- **Longhorn**: Distributed block storage

### 네트워크 확장

#### MetalLB IP Pool 확장

```yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: production
  namespace: metallb-system
spec:
  addresses:
  - 172.16.0.210-172.16.0.250  # 기존 41개
  - 172.16.1.0-172.16.1.50     # 추가 51개
```

---

## 성능 최적화

### 네트워크 최적화

- **MTU 최적화**: Calico MTU를 1450으로 설정 (VXLAN overhead)
- **Connection Tracking**: nf_conntrack_max 증가
- **TCP Tuning**: TCP window size 최적화

### 스토리지 최적화

- **NFS 튜닝**: rsize/wsize=1048576, async mount
- **I/O Scheduler**: deadline 또는 noop 스케줄러
- **Disk Cache**: Write-back cache 활성화

### 애플리케이션 최적화

- **Resource Limits**: 적절한 requests/limits 설정
- **Connection Pooling**: Database connection pooling
- **Caching**: Redis/Memcached 도입

---

## 재해 복구 (Disaster Recovery)

### 백업 전략

#### etcd 백업

```bash
# 매일 자동 백업
ETCDCTL_API=3 etcdctl snapshot save /backup/etcd-$(date +%Y%m%d).db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/ssl/etcd/ca.crt \
  --cert=/etc/kubernetes/ssl/etcd/server.crt \
  --key=/etc/kubernetes/ssl/etcd/server.key
```

#### 애플리케이션 데이터 백업

```bash
# NFS 데이터 백업
rsync -av /data/ backup-server:/backup/k-paas/$(date +%Y%m%d)/
```

### 복구 절차

#### etcd 복구

```bash
# 1. 모든 마스터 노드에서 etcd 중지
systemctl stop etcd

# 2. etcd 데이터 디렉토리 백업
mv /var/lib/etcd /var/lib/etcd.old

# 3. 스냅샷에서 복구
ETCDCTL_API=3 etcdctl snapshot restore /backup/etcd-20250127.db \
  --data-dir=/var/lib/etcd

# 4. etcd 재시작
systemctl start etcd
```

---

## 보안 강화 권장사항

### 네트워크 보안

1. **Security Group 최소화**: SSH 접근을 특정 IP로 제한
2. **VPN 사용**: 관리 작업은 VPN을 통해서만
3. **Private Subnet**: Worker 노드를 private subnet으로 이동

### 인증/인가 강화

1. **MFA 활성화**: Keycloak에서 Multi-Factor Authentication
2. **RBAC 세분화**: 최소 권한 원칙 적용
3. **Service Account 제한**: 각 애플리케이션마다 별도 SA 사용

### 데이터 보안

1. **Encryption at Rest**: etcd 데이터 암호화
2. **Secrets Management**: OpenBao로 모든 secrets 관리
3. **TLS Everywhere**: 모든 내부 통신도 TLS 사용
