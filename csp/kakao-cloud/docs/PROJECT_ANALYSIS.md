# K-PaaS 프로젝트 상세 분석

## 📋 목차

- [프로젝트 개요](#프로젝트-개요)
- [전체 아키텍처](#전체-아키텍처)
- [프로젝트 구조](#프로젝트-구조)
- [기술 스택](#기술-스택)
- [배포 환경](#배포-환경)
- [데이터 흐름](#데이터-흐름)
- [주요 컴포넌트 분석](#주요-컴포넌트-분석)
- [보안 구성](#보안-구성)
- [확장성 및 성능](#확장성-및-성능)

---

## 프로젝트 개요

### 기본 정보

| 항목 | 내용 |
|------|------|
| **프로젝트명** | K-PaaS Lite |
| **버전** | 2.0.0 |
| **K-PaaS 버전** | 1.7.0 |
| **Kubernetes 버전** | v1.33.5 |
| **라이선스** | Apache 2.0 |
| **언어** | Shell Script, Terraform (HCL) |

### 프로젝트 목적

K-PaaS는 한국형 클라우드 플랫폼을 로컬 및 클라우드 환경에 쉽게 배포할 수 있도록 자동화한 프로젝트입니다:

- **로컬 배포**: Vagrant + VirtualBox를 사용한 ARM 기반 로컬 환경 지원
- **클라우드 배포**: Terraform을 통한 Kakao Cloud 자동 프로비저닝
- **자동화**: 모든 설치 과정을 Shell Script로 자동화
- **교육 및 테스트**: 개발자가 K-PaaS를 쉽게 학습하고 테스트할 수 있는 환경 제공

---

## 전체 아키텍처

### 시스템 전체 구조도

```mermaid
graph TB
    subgraph "External Access"
        Users[사용자/개발자]
        Admin[관리자]
    end

    subgraph "Load Balancers"
        MasterLB[Master Load Balancer<br/>포트: 6443, 2379]
        WorkerLB[Worker Load Balancer<br/>포트: 80, 443]
    end

    subgraph "Control Plane - Masters (HA)"
        Master1[Master-1<br/>172.16.0.101<br/>API Server + etcd]
        Master2[Master-2<br/>172.16.0.102<br/>API Server + etcd]
        Master3[Master-3<br/>172.16.0.103<br/>API Server + etcd]

        Master1 -.-> Master2
        Master2 -.-> Master3
        Master3 -.-> Master1
    end

    subgraph "Worker Nodes"
        Worker1[Worker-1<br/>172.16.0.111<br/>App Workloads]
        Worker2[Worker-2<br/>172.16.0.112<br/>App Workloads]
        Worker3[Worker-3<br/>172.16.0.113<br/>App Workloads]
    end

    subgraph "K-PaaS Services"
        Portal[CP-Portal<br/>관리 콘솔]
        Harbor[Harbor<br/>Container Registry]
        Keycloak[Keycloak<br/>IAM]
        OpenBao[OpenBao<br/>Secrets]
    end

    subgraph "Infrastructure"
        VPC[VPC: 172.16.0.0/16]
        Storage[NFS Storage<br/>Master-1:/data]
        Network[Calico CNI<br/>Pod Network]
    end

    Users --> WorkerLB
    Admin --> MasterLB

    MasterLB --> Master1
    MasterLB --> Master2
    MasterLB --> Master3

    WorkerLB --> Worker1
    WorkerLB --> Worker2
    WorkerLB --> Worker3

    Master1 --> Worker1
    Master1 --> Worker2
    Master1 --> Worker3

    Worker1 --> Portal
    Worker1 --> Harbor
    Worker2 --> Keycloak
    Worker2 --> OpenBao

    Master1 --> Storage
    Worker1 --> Storage
    Worker2 --> Storage
    Worker3 --> Storage

    Master1 -.-> Network
    Worker1 -.-> Network
    Worker2 -.-> Network
    Worker3 -.-> Network

    VPC -.-> Master1
    VPC -.-> Master2
    VPC -.-> Master3
    VPC -.-> Worker1
    VPC -.-> Worker2
    VPC -.-> Worker3
```

### 네트워크 토폴로지

```mermaid
graph LR
    subgraph "Internet"
        Client[클라이언트]
    end

    subgraph "Kakao Cloud VPC - 172.16.0.0/16"
        subgraph "Public Subnet - 172.16.0.0/24"
            PublicIP1[Master LB Public IP]
            PublicIP2[Worker LB Public IP]
        end

        subgraph "Private Network"
            subgraph "Master Nodes"
                M1[Master-1<br/>172.16.0.101]
                M2[Master-2<br/>172.16.0.102]
                M3[Master-3<br/>172.16.0.103]
            end

            subgraph "Worker Nodes"
                W1[Worker-1<br/>172.16.0.111]
                W2[Worker-2<br/>172.16.0.112]
                W3[Worker-3<br/>172.16.0.113]
            end

            subgraph "Virtual IPs"
                VIP1[Master LB VIP<br/>172.16.0.54]
                VIP2[Worker LB VIP<br/>172.16.0.88]
                VIP3[Ingress Nginx<br/>172.16.0.201]
            end

            subgraph "Service IP Pool"
                MetalLB[MetalLB Pool<br/>172.16.0.210-250]
            end
        end
    end

    Client -->|HTTPS:6443| PublicIP1
    Client -->|HTTP/HTTPS| PublicIP2

    PublicIP1 --> VIP1
    PublicIP2 --> VIP2

    VIP1 --> M1
    VIP1 --> M2
    VIP1 --> M3

    VIP2 --> W1
    VIP2 --> W2
    VIP2 --> W3

    W1 --> VIP3
    W2 --> VIP3
    W3 --> VIP3

    VIP3 -.-> MetalLB
```

### Kubernetes 클러스터 아키텍처

```mermaid
graph TB
    subgraph "Kubernetes Control Plane"
        API[kube-apiserver<br/>Port: 6443]
        ETCD[etcd Cluster<br/>Port: 2379, 2380<br/>3-node Quorum]
        CM[kube-controller-manager]
        Sched[kube-scheduler]

        API --> ETCD
        CM --> API
        Sched --> API
    end

    subgraph "Worker Nodes"
        subgraph "Worker-1"
            Kubelet1[kubelet]
            Proxy1[kube-proxy]
            Runtime1[CRI-O]
            CNI1[Calico]
        end

        subgraph "Worker-2"
            Kubelet2[kubelet]
            Proxy2[kube-proxy]
            Runtime2[CRI-O]
            CNI2[Calico]
        end

        subgraph "Worker-3"
            Kubelet3[kubelet]
            Proxy3[kube-proxy]
            Runtime3[CRI-O]
            CNI3[Calico]
        end
    end

    subgraph "Kubernetes Add-ons"
        DNS[CoreDNS<br/>Service Discovery]
        Ingress[Ingress Nginx<br/>L7 Load Balancer]
        Metal[MetalLB<br/>L4 Load Balancer]
        Metrics[Metrics Server<br/>Monitoring]
    end

    API --> Kubelet1
    API --> Kubelet2
    API --> Kubelet3

    Kubelet1 --> Runtime1
    Kubelet2 --> Runtime2
    Kubelet3 --> Runtime3

    Runtime1 -.-> CNI1
    Runtime2 -.-> CNI2
    Runtime3 -.-> CNI3

    Proxy1 -.-> DNS
    Ingress -.-> Metal
    Metrics -.-> API
```

---

## 프로젝트 구조

### 디렉토리 구조도

```mermaid
graph TD
    Root[k-paas/]

    Root --> Docs[docs/<br/>문서 및 이미지]
    Root --> Scripts[scripts/<br/>설치 스크립트]
    Root --> CSP[csp/<br/>클라우드 배포]
    Root --> Egovframe[egovframe/<br/>표준프레임워크]
    Root --> Logs[logs/<br/>실행 로그]
    Root --> Vagrant[Vagrantfile<br/>로컬 VM 설정]

    Scripts --> GlobalVar[00.global_variable.sh<br/>환경 변수]
    Scripts --> CommonSet[01.all_common_setting.sh<br/>공통 설정]
    Scripts --> HAProxy[02.lb_haproxy.sh<br/>로드밸런서]
    Scripts --> NFS[03.master_nfs_server.sh<br/>NFS 서버]
    Scripts --> SSH[04.master_ssh_setting.sh<br/>SSH 설정]
    Scripts --> K8s[05.master_install_k-pass.sh<br/>K8s 설치]
    Scripts --> Portal[06.master_install_k-pass_portal.sh<br/>Portal 설치]

    CSP --> Kakao[kakao-cloud/<br/>Kakao Cloud 배포]
    Kakao --> TF[terraform/<br/>IaC 코드]

    TF --> MainTF[main.tf<br/>메인 설정]
    TF --> Modules[modules/<br/>재사용 모듈]

    Modules --> Network[network/<br/>VPC, Subnet]
    Modules --> Security[security/<br/>방화벽]
    Modules --> Compute[compute/<br/>VM 인스턴스]
    Modules --> LB[loadbalancer/<br/>로드밸런서]
    Modules --> Prov[provisioner/<br/>자동 설치]

    style Root fill:#e1f5ff
    style Scripts fill:#fff4e1
    style CSP fill:#e8f5e9
    style TF fill:#f3e5f5
    style Modules fill:#fce4ec
```

### 주요 파일 분석

#### 로컬 배포 (Vagrant)

| 파일 | 역할 | 라인수 |
|------|------|--------|
| `Vagrantfile` | VM 프로비저닝 설정 | 85 |
| `scripts/00.global_variable.sh` | 전역 환경 변수 | ~100 |
| `scripts/01.all_common_setting.sh` | 모든 노드 공통 설정 | ~200 |
| `scripts/05.master_install_k-pass.sh` | Kubernetes 클러스터 설치 | ~500 |
| `scripts/06.master_install_k-pass_portal.sh` | CP-Portal 설치 | ~300 |

#### 클라우드 배포 (Terraform)

| 파일 | 역할 | 리소스 |
|------|------|--------|
| `main.tf` | 모듈 오케스트레이션 | 5개 모듈 |
| `modules/network/main.tf` | VPC, Subnet 생성 | 3개 |
| `modules/security/main.tf` | Security Group | 1개 + 20개 룰 |
| `modules/compute/main.tf` | Master/Worker VM | 6개 인스턴스 |
| `modules/loadbalancer/main.tf` | Load Balancer | 2개 LB |
| `modules/provisioner/main.tf` | 자동 설치 스크립트 | 6개 스크립트 |

---

## 기술 스택

### 인프라 기술

```mermaid
graph LR
    subgraph "Infrastructure Layer"
        Vagrant[Vagrant<br/>VM 관리]
        VBox[VirtualBox<br/>Hypervisor]
        Terraform[Terraform<br/>IaC]
        Kakao[Kakao Cloud<br/>CSP]
    end

    subgraph "Orchestration Layer"
        K8s[Kubernetes<br/>v1.33.5]
        Kubespray[Kubespray<br/>K8s Installer]
        Ansible[Ansible<br/>Configuration]
    end

    subgraph "Runtime Layer"
        CRIO[CRI-O<br/>Container Runtime]
        Calico[Calico<br/>CNI Plugin]
    end

    subgraph "Application Layer"
        Portal[CP-Portal<br/>Management]
        Harbor[Harbor<br/>Registry]
        Keycloak[Keycloak<br/>SSO]
        OpenBao[OpenBao<br/>Vault]
    end

    Vagrant --> VBox
    Terraform --> Kakao

    VBox --> Kubespray
    Kakao --> Kubespray

    Kubespray --> Ansible
    Ansible --> K8s

    K8s --> CRIO
    K8s --> Calico

    K8s --> Portal
    K8s --> Harbor
    K8s --> Keycloak
    K8s --> OpenBao
```

### 기술 스택 상세

#### 1. 로컬 환경 (Vagrant)

| 기술 | 버전 | 역할 |
|------|------|------|
| **Vagrant** | 2.x | 가상 머신 자동 프로비저닝 |
| **VirtualBox** | 6.x/7.x | 하이퍼바이저 (ARM 지원) |
| **Ubuntu** | 22.04 LTS | 게스트 OS |
| **Shell Script** | Bash 5.x | 자동화 스크립트 |

**노드 구성**:
```mermaid
graph LR
    LB1[lb01<br/>1vCPU, 1GB<br/>192.168.100.121]
    LB2[lb02<br/>1vCPU, 1GB<br/>192.168.100.122]
    M1[master01<br/>2vCPU, 4GB<br/>192.168.100.101]
    M2[master02<br/>2vCPU, 4GB<br/>192.168.100.102]
    W1[worker01<br/>6vCPU, 6GB<br/>192.168.100.111]
    W2[worker02<br/>6vCPU, 6GB<br/>192.168.100.112]

    LB1 --> M1
    LB1 --> M2
    LB2 --> M1
    LB2 --> M2

    M1 --> W1
    M1 --> W2
    M2 --> W1
    M2 --> W2
```

#### 2. 클라우드 환경 (Kakao Cloud)

| 기술 | 버전 | 역할 |
|------|------|------|
| **Terraform** | >= 1.0 | Infrastructure as Code |
| **kakaocloud Provider** | v0.2.0 | Kakao Cloud 리소스 관리 |
| **Ubuntu** | 24.04 LTS | 서버 OS |
| **Instance Type** | t1i.xlarge | 4vCPU, 16GB RAM |

#### 3. Kubernetes 플랫폼

| 컴포넌트 | 버전 | 설명 |
|----------|------|------|
| **Kubernetes** | v1.33.5 | 컨테이너 오케스트레이션 |
| **Kubespray** | Latest | Ansible 기반 K8s 설치 도구 |
| **CRI-O** | v1.33.5 | OCI 기반 컨테이너 런타임 |
| **Calico** | Latest | CNI 네트워크 플러그인 |
| **CoreDNS** | Latest | 클러스터 DNS |
| **MetalLB** | Latest | 베어메탈 로드밸런서 |
| **Ingress Nginx** | Latest | L7 로드밸런서 |

#### 4. K-PaaS 애플리케이션

| 서비스 | 포트 | 역할 |
|--------|------|------|
| **CP-Portal** | 8080 | 컨테이너 플랫폼 관리 콘솔 |
| **Harbor** | 80/443 | 프라이빗 컨테이너 레지스트리 |
| **Keycloak** | 8080 | 통합 인증/인가 (SSO) |
| **OpenBao** | 8200 | 시크릿 관리 (Vault Fork) |
| **ChartMuseum** | 8080 | Helm Chart 저장소 |
| **Chaos Mesh** | - | 카오스 엔지니어링 |

---

## 배포 환경

### 배포 프로세스 플로우

```mermaid
flowchart TD
    Start([배포 시작]) --> Choice{배포 환경}

    Choice -->|로컬| Vagrant[Vagrant 배포]
    Choice -->|클라우드| Terraform[Terraform 배포]

    Vagrant --> VagrantUp[vagrant up 실행]
    VagrantUp --> CreateVM[VM 생성<br/>LB x2, Master x2, Worker x2]
    CreateVM --> CommonScript[공통 설정 스크립트]

    Terraform --> TFInit[terraform init]
    TFInit --> TFApply[terraform apply]
    TFApply --> CreateInfra[인프라 생성<br/>VPC, Subnet, SG]
    CreateInfra --> CreateCompute[컴퓨트 생성<br/>Master x3, Worker x3]
    CreateCompute --> CreateLB[Load Balancer 생성]
    CreateLB --> CommonScript

    CommonScript --> NFSSetup[NFS 서버 설정<br/>Master-1]
    NFSSetup --> SSHSetup[SSH 키 배포]
    SSHSetup --> K8sInstall[Kubernetes 설치<br/>Kubespray]

    K8sInstall --> K8sCheck{클러스터<br/>정상?}
    K8sCheck -->|No| Troubleshoot[문제 해결]
    Troubleshoot --> K8sInstall
    K8sCheck -->|Yes| PortalInstall[CP-Portal 설치]

    PortalInstall --> Services[서비스 설치<br/>Harbor, Keycloak, etc]
    Services --> Verify[배포 검증]
    Verify --> End([배포 완료])

    style Start fill:#e1f5ff
    style End fill:#c8e6c9
    style K8sCheck fill:#fff9c4
    style Troubleshoot fill:#ffccbc
```

### 로컬 배포 상세

```mermaid
sequenceDiagram
    participant User as 사용자
    participant Vagrant as Vagrant
    participant VBox as VirtualBox
    participant VM as VM 인스턴스
    participant Script as 설치 스크립트
    participant K8s as Kubernetes

    User->>Vagrant: vagrant up 실행
    Vagrant->>VBox: VM 생성 요청
    VBox->>VM: LB01, LB02 생성
    VM->>Script: 01.all_common_setting.sh
    Script->>VM: 공통 패키지 설치

    VBox->>VM: Worker01, Worker02 생성
    VM->>Script: 01.all_common_setting.sh

    VBox->>VM: Master01, Master02 생성
    VM->>Script: 01.all_common_setting.sh
    VM->>Script: 03.master_nfs_server.sh
    Script->>VM: NFS 서버 설정

    VM->>Script: 04.master_ssh_setting.sh
    Script->>VM: SSH 키 배포

    VM->>Script: 05.master_install_k-pass.sh
    Script->>K8s: Kubespray 실행
    K8s->>VM: 클러스터 구축 완료

    VM->>Script: 06.master_install_k-pass_portal.sh
    Script->>K8s: CP-Portal 배포
    K8s->>User: 배포 완료 (로그 출력)
```

### 클라우드 배포 상세 (Terraform)

```mermaid
sequenceDiagram
    participant User as 사용자
    participant TF as Terraform
    participant Kakao as Kakao Cloud API
    participant VM as VM 인스턴스
    participant Script as Provisioner
    participant K8s as Kubernetes

    User->>TF: terraform init
    TF->>TF: Provider 플러그인 다운로드

    User->>TF: terraform apply
    TF->>Kakao: VPC 생성 (172.16.0.0/16)
    Kakao-->>TF: VPC ID 반환

    TF->>Kakao: Subnet 생성 (172.16.0.0/24)
    Kakao-->>TF: Subnet ID 반환

    TF->>Kakao: Security Group 생성
    Kakao-->>TF: SG ID 반환

    TF->>Kakao: Master x3, Worker x3 생성
    Kakao-->>VM: 인스턴스 프로비저닝
    VM-->>TF: Public/Private IP 반환

    TF->>Kakao: Load Balancer 생성 (Master, Worker)
    Kakao-->>TF: LB Public IP 반환

    TF->>Script: Provisioner 실행
    Script->>VM: 스크립트 복사
    Script->>VM: 00.global_variable.sh
    Script->>VM: 01.all_common_setting.sh
    Script->>VM: 03.master_nfs_server.sh
    Script->>VM: 04.master_ssh_setting.sh
    Script->>VM: 05.master_install_k-pass.sh

    VM->>K8s: Kubespray 실행
    K8s-->>VM: 클러스터 Ready

    Script->>VM: 06.master_install_k-pass_portal.sh
    VM->>K8s: Portal 배포
    K8s-->>User: 배포 완료 (terraform output)
```

---

## 데이터 흐름

### 사용자 요청 플로우 (외부 → 애플리케이션)

```mermaid
flowchart LR
    subgraph External
        User[사용자 브라우저]
    end

    subgraph "Public Network"
        DNS[DNS<br/>portal.k-paas.io<br/>→ Public IP]
    end

    subgraph "Load Balancer"
        WorkerLB[Worker LB<br/>Public IP:443]
    end

    subgraph "Worker Nodes"
        NodePort[NodePort 31443<br/>모든 Worker 노드]
    end

    subgraph "Ingress"
        Ingress[Ingress Nginx<br/>172.16.0.201]
    end

    subgraph "Service"
        PortalSvc[Portal Service<br/>ClusterIP]
    end

    subgraph "Application"
        PortalPod[Portal Pod<br/>Container:8080]
    end

    subgraph "Backend Services"
        K8sAPI[Kubernetes API]
        KeycloakSvc[Keycloak<br/>인증]
    end

    User -->|1. HTTPS 요청| DNS
    DNS -->|2. IP 반환| User
    User -->|3. TLS 연결| WorkerLB
    WorkerLB -->|4. 트래픽 분산| NodePort
    NodePort -->|5. 포워딩| Ingress
    Ingress -->|6. 호스트 기반 라우팅| PortalSvc
    PortalSvc -->|7. Pod 로드밸런싱| PortalPod
    PortalPod -->|8. 인증 요청| KeycloakSvc
    KeycloakSvc -->|9. Token 발급| PortalPod
    PortalPod -->|10. API 호출| K8sAPI
    K8sAPI -->|11. 리소스 반환| PortalPod
    PortalPod -->|12. 응답| User
```

### Pod 간 통신 플로우

```mermaid
flowchart TB
    subgraph "Worker Node 1"
        Pod1[Application Pod<br/>IP: 10.233.64.10]
        CNI1[Calico CNI]
        Kubelet1[kubelet]
    end

    subgraph "Worker Node 2"
        Pod2[Database Pod<br/>IP: 10.233.65.20]
        CNI2[Calico CNI]
        Kubelet2[kubelet]
    end

    subgraph "Kubernetes Network"
        Service[Service<br/>ClusterIP: 10.233.10.50]
        CoreDNS[CoreDNS<br/>10.233.0.3]
        Proxy[kube-proxy<br/>iptables rules]
    end

    Pod1 -->|1. DNS 쿼리<br/>database-service| CoreDNS
    CoreDNS -->|2. ClusterIP 반환<br/>10.233.10.50| Pod1
    Pod1 -->|3. TCP 연결 시도<br/>10.233.10.50:5432| Proxy
    Proxy -->|4. DNAT 규칙 적용<br/>→ 10.233.65.20:5432| CNI1
    CNI1 -->|5. VXLAN Tunnel| CNI2
    CNI2 -->|6. 패킷 전달| Pod2
    Pod2 -->|7. 응답| CNI2
    CNI2 -->|8. VXLAN Tunnel| CNI1
    CNI1 -->|9. 응답 전달| Pod1
```

### 스토리지 데이터 흐름

```mermaid
flowchart LR
    subgraph "Application"
        App[Application Pod]
        PVC[PersistentVolumeClaim<br/>harbor-pvc<br/>20Gi]
    end

    subgraph "Kubernetes Storage"
        PV[PersistentVolume<br/>NFS Type]
        SC[StorageClass<br/>nfs-client]
        Provisioner[NFS Provisioner<br/>Pod]
    end

    subgraph "NFS Server (Master-1)"
        NFSServer[NFS Service<br/>172.16.0.101:/data]
        Export[/data/harbor-pvc-xxx]
    end

    subgraph "Physical Storage"
        Disk[Local Disk<br/>/dev/vda<br/>200GB SSD]
    end

    App -->|1. Volume Mount 요청| PVC
    PVC -->|2. Bound to| PV
    PV -->|3. Provisioned by| SC
    SC -->|4. Dynamic provisioning| Provisioner
    Provisioner -->|5. NFS 마운트 요청| NFSServer
    NFSServer -->|6. Export 생성| Export
    Export -->|7. 물리 디스크 사용| Disk
    Disk -->|8. I/O| Export
    Export -->|9. NFS Protocol| App
```

---

## 주요 컴포넌트 분석

### 1. Vagrant 로컬 배포

#### VM 구성 흐름

```mermaid
stateDiagram-v2
    [*] --> VagrantInit: vagrant up

    VagrantInit --> CreateLB: LB 노드 생성
    CreateLB --> LB1: lb01 (1vCPU, 1GB)
    CreateLB --> LB2: lb02 (1vCPU, 1GB)

    LB1 --> ConfigLB1: HAProxy 설정
    LB2 --> ConfigLB2: HAProxy 설정

    ConfigLB1 --> CreateWorker
    ConfigLB2 --> CreateWorker

    CreateWorker --> Worker1: worker01 (6vCPU, 6GB)
    CreateWorker --> Worker2: worker02 (6vCPU, 6GB)

    Worker1 --> ConfigWorker1: 공통 설정
    Worker2 --> ConfigWorker2: 공통 설정

    ConfigWorker1 --> CreateMaster
    ConfigWorker2 --> CreateMaster

    CreateMaster --> Master2: master02 (2vCPU, 4GB)
    CreateMaster --> Master1: master01 (2vCPU, 4GB)

    Master2 --> ConfigMaster2: 공통 설정
    Master1 --> ConfigMaster1: 공통 설정

    ConfigMaster1 --> NFSSetup: NFS 서버 구성
    NFSSetup --> SSHSetup: SSH 키 배포
    SSHSetup --> K8sInstall: Kubernetes 설치
    K8sInstall --> PortalInstall: Portal 설치

    PortalInstall --> [*]: 배포 완료
```

#### HAProxy 구성

```mermaid
graph TB
    subgraph "HAProxy Load Balancers"
        LB1[lb01<br/>192.168.100.121<br/>VIP: 192.168.100.200]
        LB2[lb02<br/>192.168.100.122<br/>VIP: 192.168.100.200]

        LB1 -.keepalived.-> LB2
    end

    subgraph "Backend - K8s API"
        M1[master01:6443]
        M2[master02:6443]
    end

    subgraph "Backend - Ingress"
        W1[worker01:31080/31443]
        W2[worker02:31080/31443]
    end

    Client[클라이언트] -->|cluster-endpoint:6443| LB1
    Client -->|k-paas.io:443| LB1

    LB1 -->|Round Robin| M1
    LB1 -->|Round Robin| M2

    LB1 -->|Round Robin| W1
    LB1 -->|Round Robin| W2

    style LB1 fill:#bbdefb
    style LB2 fill:#c5cae9
```

### 2. Terraform 클라우드 배포

#### Terraform 모듈 구조

```mermaid
graph TB
    Main[main.tf<br/>Root Module]

    Main --> Network[Module: Network]
    Main --> Security[Module: Security]
    Main --> Compute[Module: Compute]
    Main --> LB[Module: LoadBalancer]
    Main --> Prov[Module: Provisioner]

    subgraph "Network Module"
        VPC[VPC<br/>172.16.0.0/16]
        Subnet[Subnet<br/>172.16.0.0/24]
        VPC --> Subnet
    end

    subgraph "Security Module"
        SG[Security Group]
        Rules[Ingress/Egress Rules<br/>22, 6443, 80, 443, etc]
        SG --> Rules
    end

    subgraph "Compute Module"
        Masters[Master Instances x3<br/>t1i.xlarge, 200GB]
        Workers[Worker Instances x3<br/>t1i.xlarge, 200GB]
        PubIP[Public IPs x6]
        Masters --> PubIP
        Workers --> PubIP
    end

    subgraph "LoadBalancer Module"
        MasterLB[Master LB<br/>NLB L4<br/>Port: 6443, 2379]
        WorkerLB[Worker LB<br/>NLB L4<br/>Port: 80, 443]
    end

    subgraph "Provisioner Module"
        Scripts[Installation Scripts]
        SSH[SSH Connection]
        Exec[Remote Execution]
        Scripts --> SSH
        SSH --> Exec
    end

    Network --> Compute
    Security --> Compute
    Compute --> LB
    LB --> Prov

    style Main fill:#e1bee7
    style Network fill:#c5e1a5
    style Security fill:#ffccbc
    style Compute fill:#b3e5fc
    style LB fill:#f0f4c3
    style Prov fill:#ffecb3
```

#### 리소스 의존성 그래프

```mermaid
graph TD
    TFVars[terraform.tfvars<br/>변수 정의]

    TFVars --> CreateVPC[VPC 생성]
    CreateVPC --> CreateSubnet[Subnet 생성]
    CreateSubnet --> CreateSG[Security Group 생성]

    CreateSG --> CreateMaster1[Master-1 생성]
    CreateSG --> CreateMaster2[Master-2 생성]
    CreateSG --> CreateMaster3[Master-3 생성]
    CreateSG --> CreateWorker1[Worker-1 생성]
    CreateSG --> CreateWorker2[Worker-2 생성]
    CreateSG --> CreateWorker3[Worker-3 생성]

    CreateMaster1 --> AllocPubIP1[Public IP 할당]
    CreateMaster2 --> AllocPubIP2[Public IP 할당]
    CreateMaster3 --> AllocPubIP3[Public IP 할당]
    CreateWorker1 --> AllocPubIP4[Public IP 할당]
    CreateWorker2 --> AllocPubIP5[Public IP 할당]
    CreateWorker3 --> AllocPubIP6[Public IP 할당]

    AllocPubIP1 --> CreateMasterLB[Master LB 생성]
    AllocPubIP2 --> CreateMasterLB
    AllocPubIP3 --> CreateMasterLB

    AllocPubIP4 --> CreateWorkerLB[Worker LB 생성]
    AllocPubIP5 --> CreateWorkerLB
    AllocPubIP6 --> CreateWorkerLB

    CreateMasterLB --> GenScripts[스크립트 생성]
    CreateWorkerLB --> GenScripts

    GenScripts --> ExecScript1[00.global_variable.sh]
    ExecScript1 --> ExecScript2[01.all_common_setting.sh]
    ExecScript2 --> ExecScript3[03.master_nfs_server.sh]
    ExecScript3 --> ExecScript4[04.master_ssh_setting.sh]
    ExecScript4 --> ExecScript5[05.master_install_k-pass.sh]
    ExecScript5 --> ExecScript6[06.master_install_k-pass_portal.sh]

    ExecScript6 --> TFOutput[terraform output<br/>배포 완료]

    style TFVars fill:#e1f5ff
    style TFOutput fill:#c8e6c9
```

### 3. Kubernetes 설치 프로세스 (Kubespray)

```mermaid
flowchart TD
    Start([설치 시작]) --> DownloadKS[Kubespray Clone]
    DownloadKS --> GenInventory[Inventory 생성<br/>hosts.yaml]

    GenInventory --> SetVars[변수 설정<br/>cp-cluster-vars.sh]
    SetVars --> PreCheck[사전 요구사항 체크]

    PreCheck --> InstallDeps[의존성 설치<br/>Python, Ansible]
    InstallDeps --> RunPlaybook[Ansible Playbook 실행]

    RunPlaybook --> Bootstrap[Bootstrap 단계<br/>OS 설정, 패키지]
    Bootstrap --> InstallDocker[Container Runtime<br/>CRI-O 설치]
    InstallDocker --> InstallEtcd[etcd 클러스터 구성]

    InstallEtcd --> InstallMaster[Control Plane 설치<br/>API, Controller, Scheduler]
    InstallMaster --> InstallWorker[Worker 노드 Join]

    InstallWorker --> InstallCNI[CNI 설치<br/>Calico]
    InstallCNI --> InstallDNS[DNS 설치<br/>CoreDNS]
    InstallDNS --> InstallIngress[Ingress 설치<br/>Nginx]

    InstallIngress --> InstallMetalLB[MetalLB 설치]
    InstallMetalLB --> InstallMetrics[Metrics Server 설치]

    InstallMetrics --> Verify{클러스터<br/>검증}
    Verify -->|Fail| Debug[로그 확인 및 디버그]
    Debug --> RunPlaybook

    Verify -->|Success| End([K8s 설치 완료])

    style Start fill:#e1f5ff
    style End fill:#c8e6c9
    style Verify fill:#fff9c4
    style Debug fill:#ffccbc
```

### 4. CP-Portal 설치 프로세스

```mermaid
sequenceDiagram
    participant Script as 설치 스크립트
    participant Git as GitHub
    participant K8s as Kubernetes
    participant Harbor as Harbor
    participant Keycloak as Keycloak
    participant OpenBao as OpenBao
    participant Portal as CP-Portal

    Script->>Git: cp-portal-deployment 클론
    Git-->>Script: 소스 코드 다운로드

    Script->>Script: 환경 변수 설정<br/>(domain, IP, etc)

    Script->>K8s: Namespace 생성<br/>(harbor, keycloak, openbao, cp-portal)
    K8s-->>Script: Namespace Ready

    Script->>K8s: Harbor 배포 (Helm)
    K8s->>Harbor: Deployment, Service, PVC
    Harbor-->>Script: Harbor Ready

    Script->>K8s: Keycloak 배포
    K8s->>Keycloak: StatefulSet, DB
    Keycloak-->>Script: Keycloak Ready

    Script->>K8s: OpenBao 배포
    K8s->>OpenBao: Deployment, Storage
    OpenBao-->>Script: OpenBao Ready

    Script->>OpenBao: 초기화 및 Unseal
    OpenBao-->>Script: Root Token 생성

    Script->>Keycloak: Realm 생성<br/>Client 설정
    Keycloak-->>Script: OAuth2 Client ID

    Script->>K8s: CP-Portal 배포<br/>(UI, API, Metric, etc)
    K8s->>Portal: Pods 생성
    Portal-->>Script: Portal Ready

    Script->>K8s: Ingress 설정<br/>(portal.k-paas.io)
    K8s-->>Script: Ingress Ready

    Script->>Script: 접속 정보 출력<br/>(URL, Password)
```

---

## 보안 구성

### 네트워크 보안 계층

```mermaid
graph TB
    subgraph "Internet"
        Attacker[외부 접근]
    end

    subgraph "Security Layers"
        subgraph "Layer 1: Cloud Firewall"
            CloudFW[Kakao Cloud Security Group<br/>포트 제한: 22, 6443, 80, 443]
        end

        subgraph "Layer 2: Load Balancer"
            LB[NLB Health Check<br/>비정상 노드 자동 제외]
        end

        subgraph "Layer 3: Kubernetes Network Policy"
            NetPolicy[Network Policy<br/>Namespace 격리<br/>Pod 간 통신 제어]
        end

        subgraph "Layer 4: Service Mesh (선택)"
            ServiceMesh[Service Mesh<br/>mTLS<br/>트래픽 암호화]
        end

        subgraph "Layer 5: Application Auth"
            AppAuth[Keycloak SSO<br/>RBAC<br/>JWT Token]
        end
    end

    subgraph "Protected Resources"
        Apps[Applications<br/>Pods]
    end

    Attacker -->|1. 접근 시도| CloudFW
    CloudFW -->|2. 허용된 포트만| LB
    LB -->|3. 정상 노드로 라우팅| NetPolicy
    NetPolicy -->|4. Policy 허용| ServiceMesh
    ServiceMesh -->|5. mTLS 검증| AppAuth
    AppAuth -->|6. 인증/인가 성공| Apps

    style CloudFW fill:#ffccbc
    style AppAuth fill:#c8e6c9
```

### Security Group 규칙 상세

```mermaid
graph LR
    subgraph "Ingress Rules"
        SSH[SSH<br/>TCP 22<br/>From: 0.0.0.0/0]
        K8sAPI[Kubernetes API<br/>TCP 6443<br/>From: 0.0.0.0/0]
        ETCD[etcd<br/>TCP 2379-2380<br/>From: VPC]
        Kubelet[Kubelet API<br/>TCP 10250<br/>From: VPC]
        HTTP[HTTP/HTTPS<br/>TCP 80, 443<br/>From: 0.0.0.0/0]
        NodePort[NodePort<br/>TCP 30000-32767<br/>From: 0.0.0.0/0]
        Calico[Calico<br/>UDP 8472<br/>TCP 179, 5473<br/>From: VPC]
        NFS[NFS<br/>TCP 2049<br/>From: VPC]
    end

    subgraph "Egress Rules"
        AllOut[All Traffic<br/>All Protocols<br/>To: 0.0.0.0/0]
    end

    Internet[Internet] -->|허용| SSH
    Internet -->|허용| K8sAPI
    Internet -->|허용| HTTP
    Internet -->|허용| NodePort

    VPC[VPC 내부<br/>172.16.0.0/16] -->|허용| ETCD
    VPC -->|허용| Kubelet
    VPC -->|허용| Calico
    VPC -->|허용| NFS

    AllResources[모든 리소스] -->|허용| AllOut

    style SSH fill:#ffccbc
    style K8sAPI fill:#fff9c4
    style HTTP fill:#c8e6c9
```

### 인증 및 인가 플로우

```mermaid
sequenceDiagram
    participant User as 사용자
    participant Portal as CP-Portal UI
    participant Keycloak as Keycloak
    participant K8sAPI as Kubernetes API
    participant RBAC as RBAC
    participant Resource as 리소스

    User->>Portal: 1. 로그인 시도
    Portal->>Keycloak: 2. 인증 요청<br/>(username, password)
    Keycloak->>Keycloak: 3. 사용자 검증<br/>(LDAP/DB)
    Keycloak-->>Portal: 4. JWT Token 발급<br/>(Access + Refresh)
    Portal-->>User: 5. 로그인 성공

    User->>Portal: 6. 리소스 요청<br/>(예: Pod 목록)
    Portal->>K8sAPI: 7. API 호출<br/>(Authorization: Bearer <token>)
    K8sAPI->>Keycloak: 8. Token 검증<br/>(OIDC)
    Keycloak-->>K8sAPI: 9. Token Valid + User Info

    K8sAPI->>RBAC: 10. 권한 확인<br/>(User, Verb, Resource)
    RBAC->>RBAC: 11. RoleBinding 조회
    RBAC-->>K8sAPI: 12. 권한 있음

    K8sAPI->>Resource: 13. 리소스 조회
    Resource-->>K8sAPI: 14. 데이터 반환
    K8sAPI-->>Portal: 15. 응답
    Portal-->>User: 16. UI 표시
```

### TLS/SSL 인증서 구조

```mermaid
graph TB
    subgraph "Certificate Authority"
        RootCA[Self-Signed CA<br/>k-paas-root-ca]
    end

    subgraph "Kubernetes Certificates"
        K8sCA[Kubernetes CA<br/>/etc/kubernetes/ssl/ca.crt]
        APICRT[API Server Cert<br/>apiserver.crt<br/>SAN: cluster-endpoint, *.k-paas.io]
        EtcdCRT[etcd Cert<br/>etcd/server.crt]
        KubeletCRT[Kubelet Certs<br/>kubelet-client.pem]
    end

    subgraph "Application Certificates"
        HarborCRT[harbor.k-paas.io.crt<br/>Self-Signed]
        KeycloakCRT[keycloak.k-paas.io.crt<br/>Self-Signed]
        PortalCRT[portal.k-paas.io.crt<br/>Self-Signed]
        OpenBaoCRT[openbao.k-paas.io.crt<br/>Self-Signed]
    end

    RootCA -->|서명| K8sCA
    K8sCA -->|서명| APICRT
    K8sCA -->|서명| EtcdCRT
    K8sCA -->|서명| KubeletCRT

    RootCA -->|서명| HarborCRT
    RootCA -->|서명| KeycloakCRT
    RootCA -->|서명| PortalCRT
    RootCA -->|서명| OpenBaoCRT

    style RootCA fill:#ffccbc
    style K8sCA fill:#fff9c4
    style HarborCRT fill:#c8e6c9
    style KeycloakCRT fill:#c8e6c9
    style PortalCRT fill:#c8e6c9
    style OpenBaoCRT fill:#c8e6c9
```

---

## 확장성 및 성능

### 수평 확장 (Scale-Out) 전략

```mermaid
graph TB
    subgraph "현재 구성 (6 Nodes)"
        M1[Master-1]
        M2[Master-2]
        M3[Master-3]
        W1[Worker-1]
        W2[Worker-2]
        W3[Worker-3]
    end

    subgraph "확장 시나리오 1: Worker 추가"
        W4[Worker-4<br/>NEW]
        W5[Worker-5<br/>NEW]
    end

    subgraph "확장 시나리오 2: Master 추가 (HA 강화)"
        M4[Master-4<br/>NEW<br/>etcd 5-node]
        M5[Master-5<br/>NEW<br/>etcd 5-node]
    end

    subgraph "자동 확장"
        HPA[Horizontal Pod Autoscaler<br/>CPU/Memory 기반<br/>자동 Pod 복제]
        CA[Cluster Autoscaler<br/>Node 부족 시<br/>자동 Node 추가]
    end

    W1 -.-> W4
    W2 -.-> W5

    M1 -.-> M4
    M2 -.-> M5

    W4 --> HPA
    HPA --> CA

    style W4 fill:#c8e6c9
    style W5 fill:#c8e6c9
    style M4 fill:#bbdefb
    style M5 fill:#bbdefb
```

### 성능 최적화 포인트

```mermaid
mindmap
  root((성능 최적화))
    Network
      MTU 최적화 1450
      TCP Window Scaling
      Connection Tracking 증가
      nf_conntrack_max 높이기
    Storage
      NFS rsize/wsize 1048576
      Async Mount
      I/O Scheduler deadline
      SSD Write-back Cache
    Kubernetes
      Resource Limits 적절 설정
      PodDisruptionBudget 설정
      Node Affinity 활용
      Anti-Affinity Pod 분산
    Application
      Connection Pooling
      Database Index 최적화
      Redis Caching
      CDN 정적 콘텐츠
    Monitoring
      Prometheus Metrics
      Grafana Dashboard
      Alert Manager
      Resource 모니터링
```

### 고가용성 (HA) 구성

```mermaid
graph TB
    subgraph "Control Plane HA"
        LB[Master Load Balancer<br/>Health Check: /healthz]
        M1[Master-1<br/>Active]
        M2[Master-2<br/>Active]
        M3[Master-3<br/>Active]

        LB --> M1
        LB --> M2
        LB --> M3

        M1 -.etcd Raft.-> M2
        M2 -.etcd Raft.-> M3
        M3 -.etcd Raft.-> M1
    end

    subgraph "etcd Quorum"
        Quorum[Quorum: 2/3<br/>Fault Tolerance: 1 node<br/>Leader Election: Raft]
    end

    subgraph "Worker HA"
        W1[Worker-1<br/>Pod Replica 1]
        W2[Worker-2<br/>Pod Replica 2]
        W3[Worker-3<br/>Pod Replica 3]

        W1 -.Pod Anti-Affinity.-> W2
        W2 -.Pod Anti-Affinity.-> W3
    end

    subgraph "Data HA"
        NFS[NFS Server<br/>Master-1]
        Backup[NFS Backup<br/>Daily rsync]
        NFS -.-> Backup
    end

    M1 -.-> Quorum
    M2 -.-> Quorum
    M3 -.-> Quorum

    M1 --> W1
    M1 --> W2
    M1 --> W3

    W1 --> NFS
    W2 --> NFS
    W3 --> NFS

    style LB fill:#ffccbc
    style Quorum fill:#fff9c4
    style NFS fill:#c8e6c9
    style Backup fill:#b2dfdb
```

### 장애 복구 시나리오

```mermaid
stateDiagram-v2
    [*] --> Normal: 정상 운영

    Normal --> MasterFail: Master 노드 1개 장애
    Normal --> WorkerFail: Worker 노드 1개 장애
    Normal --> LBFail: Load Balancer 장애
    Normal --> NFSFail: NFS 서버 장애

    MasterFail --> AutoRecover1: etcd Quorum 유지<br/>(2/3 정상)
    AutoRecover1 --> Normal: 자동 복구<br/>LB Health Check

    WorkerFail --> AutoRecover2: Pod 재스케줄링<br/>(다른 Worker로 이동)
    AutoRecover2 --> Normal: 자동 복구

    LBFail --> ManualRecover1: 수동 복구 필요<br/>LB 재시작
    ManualRecover1 --> Normal

    NFSFail --> ManualRecover2: 수동 복구<br/>Backup에서 복원
    ManualRecover2 --> Normal

    MasterFail --> QuorumLost: etcd Quorum 상실<br/>(2개 이상 장애)
    QuorumLost --> Emergency: 긴급 복구 모드
    Emergency --> Restore: etcd Snapshot 복원
    Restore --> Normal
```

---

## 주요 설치 스크립트 분석

### 스크립트 실행 순서

```mermaid
flowchart TD
    Start([스크립트 실행 시작]) --> Script00[00.global_variable.sh<br/>전역 환경 변수 설정]

    Script00 --> Script01[01.all_common_setting.sh<br/>모든 노드 공통 설정]

    subgraph "공통 설정 내용"
        Hosts[/etc/hosts 설정]
        Swap[Swap 비활성화]
        Firewall[방화벽 설정]
        Packages[필수 패키지 설치<br/>curl, wget, git, etc]
        Kernel[커널 모듈 로드<br/>br_netfilter, overlay]
    end

    Script01 --> Script02{노드 타입?}

    Script02 -->|LB 노드| Script02LB[02.lb_haproxy.sh<br/>HAProxy 설치 및 설정]
    Script02LB --> End1([LB 노드 완료])

    Script02 -->|Worker 노드| End2([Worker 노드 대기])

    Script02 -->|Master 노드| Script03[03.master_nfs_server.sh<br/>NFS 서버 설정]

    Script03 --> Script04[04.master_ssh_setting.sh<br/>SSH 키 배포]

    Script04 --> Script05[05.master_install_k-pass.sh<br/>Kubernetes 클러스터 설치]

    subgraph "K8s 설치 내용"
        Clone[Kubespray Clone]
        Inventory[Inventory 생성]
        Vars[변수 설정]
        Ansible[Ansible Playbook 실행]
        Verify[클러스터 검증]
    end

    Script05 --> Script06[06.master_install_k-pass_portal.sh<br/>CP-Portal 설치]

    subgraph "Portal 설치 내용"
        Harbor[Harbor 배포]
        Keycloak[Keycloak 배포]
        OpenBao[OpenBao 배포]
        PortalUI[CP-Portal UI/API 배포]
        Ingress[Ingress 설정]
    end

    Script06 --> End3([Master 노드 완료<br/>전체 설치 완료])

    style Start fill:#e1f5ff
    style End1 fill:#c8e6c9
    style End2 fill:#fff9c4
    style End3 fill:#81c784
```

### 주요 스크립트 상세

#### 1. 00.global_variable.sh

```bash
# 주요 환경 변수 설정
K8S_VERSION="v1.33.5"
KPAAS_VERSION="1.6.2"
MASTER_IP="192.168.100.101"
VIP_ADDRESS="192.168.100.200"
METALLB_IP_RANGE="192.168.100.210-192.168.100.250"
INGRESS_NGINX_IP="192.168.100.201"
DOMAIN="k-paas.io"
```

#### 2. 05.master_install_k-pass.sh 주요 단계

```mermaid
sequenceDiagram
    participant Script as 스크립트
    participant Git as GitHub
    participant Kubespray as Kubespray
    participant Ansible as Ansible
    participant K8s as Kubernetes

    Script->>Git: Kubespray 저장소 클론
    Git-->>Script: 소스 다운로드

    Script->>Script: Python venv 생성<br/>의존성 설치
    Script->>Script: Inventory 파일 생성<br/>(hosts.yaml)

    Script->>Kubespray: 변수 파일 설정<br/>(all.yml, k8s-cluster.yml)

    Script->>Ansible: cluster.yml 실행
    Ansible->>K8s: Bootstrap OS
    Ansible->>K8s: etcd 설치
    Ansible->>K8s: Control Plane 설치
    Ansible->>K8s: Worker 조인
    Ansible->>K8s: CNI (Calico) 설치
    Ansible->>K8s: Add-ons 설치

    K8s-->>Script: 클러스터 Ready

    Script->>K8s: kubectl get nodes
    K8s-->>Script: 노드 상태 확인
```

---

## 모니터링 및 로깅

### 모니터링 아키텍처

```mermaid
graph TB
    subgraph "Data Sources"
        K8s[Kubernetes Metrics<br/>kube-state-metrics]
        Node[Node Exporter<br/>시스템 메트릭]
        App[Application Metrics<br/>/metrics endpoint]
        CAdvisor[cAdvisor<br/>Container 메트릭]
    end

    subgraph "Collection Layer"
        Prometheus[Prometheus<br/>Time-Series DB<br/>메트릭 수집/저장]
    end

    subgraph "Visualization Layer"
        Grafana[Grafana<br/>Dashboard<br/>시각화]
    end

    subgraph "Alerting Layer"
        AlertManager[Alert Manager<br/>알림 관리]
        Webhook[Webhook<br/>Slack, Email, etc]
    end

    subgraph "Logging Layer"
        FluentBit[Fluent Bit<br/>Log Collector]
        Loki[Loki<br/>Log Aggregation]
        LogDash[Grafana<br/>Log Viewer]
    end

    K8s --> Prometheus
    Node --> Prometheus
    App --> Prometheus
    CAdvisor --> Prometheus

    Prometheus --> Grafana
    Prometheus --> AlertManager

    AlertManager --> Webhook

    K8s -.logs.-> FluentBit
    Node -.logs.-> FluentBit
    App -.logs.-> FluentBit

    FluentBit --> Loki
    Loki --> LogDash

    style Prometheus fill:#ffccbc
    style Grafana fill:#c8e6c9
    style AlertManager fill:#fff9c4
```

### 주요 메트릭

| 카테고리 | 메트릭 | 설명 |
|---------|--------|------|
| **클러스터** | `kube_node_status_condition` | 노드 상태 |
| | `kube_pod_status_phase` | Pod 상태 |
| | `kube_deployment_status_replicas` | Deployment 복제본 수 |
| **리소스** | `node_cpu_seconds_total` | CPU 사용률 |
| | `node_memory_MemAvailable_bytes` | 메모리 가용량 |
| | `node_filesystem_avail_bytes` | 디스크 가용 공간 |
| **네트워크** | `node_network_receive_bytes_total` | 네트워크 수신 |
| | `node_network_transmit_bytes_total` | 네트워크 송신 |
| **애플리케이션** | `http_requests_total` | HTTP 요청 수 |
| | `http_request_duration_seconds` | 응답 시간 |

---

## 문제 해결 가이드

### 일반적인 문제 및 해결

```mermaid
flowchart TD
    Problem{문제 발생}

    Problem -->|Pod 시작 안됨| PodIssue[Pod 문제]
    Problem -->|서비스 접근 안됨| SvcIssue[Service 문제]
    Problem -->|노드 Not Ready| NodeIssue[Node 문제]
    Problem -->|인증 실패| AuthIssue[인증 문제]

    PodIssue --> CheckPod[kubectl describe pod]
    CheckPod --> PodReason{원인?}
    PodReason -->|ImagePullBackOff| FixImage[이미지 확인<br/>Registry 접근 확인]
    PodReason -->|CrashLoopBackOff| FixCrash[로그 확인<br/>kubectl logs]
    PodReason -->|Pending| FixPending[리소스 부족<br/>노드 확인]

    SvcIssue --> CheckSvc[kubectl get svc, ep]
    CheckSvc --> SvcReason{원인?}
    SvcReason -->|Endpoint 없음| FixEP[Pod Selector 확인<br/>Pod 상태 확인]
    SvcReason -->|LoadBalancer Pending| FixLB[MetalLB 설정 확인<br/>IP Pool 확인]

    NodeIssue --> CheckNode[kubectl describe node]
    CheckNode --> NodeReason{원인?}
    NodeReason -->|Disk Pressure| FixDisk[디스크 정리<br/>Docker 이미지 삭제]
    NodeReason -->|Memory Pressure| FixMem[메모리 확보<br/>Pod Eviction]
    NodeReason -->|Network 문제| FixNet[CNI 확인<br/>Calico 재시작]

    AuthIssue --> CheckAuth[Token 확인]
    CheckAuth --> AuthReason{원인?}
    AuthReason -->|Token 만료| FixToken[Keycloak에서<br/>새 Token 발급]
    AuthReason -->|권한 없음| FixPerm[RBAC 설정 확인<br/>RoleBinding 확인]

    FixImage --> Resolved([해결])
    FixCrash --> Resolved
    FixPending --> Resolved
    FixEP --> Resolved
    FixLB --> Resolved
    FixDisk --> Resolved
    FixMem --> Resolved
    FixNet --> Resolved
    FixToken --> Resolved
    FixPerm --> Resolved

    style Problem fill:#ffccbc
    style Resolved fill:#c8e6c9
```

### 디버깅 명령어 체크리스트

```mermaid
mindmap
  root((디버깅 명령어))
    클러스터 상태
      kubectl cluster-info
      kubectl get nodes -o wide
      kubectl get componentstatuses
      kubectl top nodes
    Pod 문제
      kubectl get pods -A
      kubectl describe pod POD_NAME
      kubectl logs POD_NAME
      kubectl logs POD_NAME --previous
      kubectl exec -it POD_NAME -- bash
    Service 문제
      kubectl get svc -A
      kubectl get endpoints
      kubectl describe svc SERVICE_NAME
      kubectl get ingress -A
    네트워크 문제
      kubectl get netpol
      ip addr show
      ip route show
      iptables -L -n -v
      calicoctl node status
    스토리지 문제
      kubectl get pv,pvc -A
      kubectl describe pv PV_NAME
      showmount -e NFS_SERVER
      df -h
    이벤트 확인
      kubectl get events -A --sort-by='.lastTimestamp'
      kubectl describe node NODE_NAME
```

---

## 참고 자료

### 공식 문서

- **K-PaaS**: https://github.com/k-paas
- **Kubernetes**: https://kubernetes.io/docs/
- **Kubespray**: https://kubespray.io/
- **Terraform**: https://www.terraform.io/docs/
- **Kakao Cloud**: https://cloud.kakao.com/docs/

### 주요 컴포넌트 문서

- **Harbor**: https://goharbor.io/docs/
- **Keycloak**: https://www.keycloak.org/documentation
- **OpenBao**: https://openbao.org/docs/
- **Calico**: https://docs.tigera.io/calico/latest/
- **MetalLB**: https://metallb.universe.tf/

### 프로젝트 파일

| 파일 | 경로 | 설명 |
|------|------|------|
| 메인 README | `/README.md` | 프로젝트 개요 |
| Kakao Cloud README | `/csp/kakao-cloud/terraform/README.md` | Terraform 배포 가이드 |
| 아키텍처 문서 | `/csp/kakao-cloud/terraform/ARCHITECTURE.md` | 상세 아키텍처 |
| 설치 가이드 | `/INSTALL.md` | 설치 매뉴얼 |

---

## 버전 정보

| 구분 | 버전 | 릴리스 날짜 |
|------|------|------------|
| **프로젝트** | 2.0.0 | 2025 |
| **K-PaaS** | 1.6.2 | 2024 |
| **Kubernetes** | v1.33.5 | 2025 |
| **CRI-O** | v1.33.5 | 2025 |
| **Ubuntu (로컬)** | 22.04 LTS | 2022 |
| **Ubuntu (클라우드)** | 24.04 LTS | 2024 |
| **Terraform** | >= 1.0 | - |
| **Vagrant** | >= 2.0 | - |

---

## 라이선스

이 프로젝트는 **Apache License 2.0** 라이선스를 따릅니다.

---

## 기여자

- **Kiha Lee** ([dasomel](https://github.com/dasomel)) - Founder

### 지원 기관

이 프로젝트는 [Kakao Enterprise](https://kakaoenterprise.com)의 지원을 받아 개발되었습니다.

---

## 문의 및 지원

- **Issues**: GitHub Issues 페이지
- **문서**: 프로젝트 내 README.md 및 docs/ 디렉토리
- **로그**: `/home/ubuntu/kpaas_install.log` (클라우드 배포 시)

---

**생성일**: 2025-11-30
**문서 버전**: 1.0.0
**작성**: Claude AI (Anthropic)
