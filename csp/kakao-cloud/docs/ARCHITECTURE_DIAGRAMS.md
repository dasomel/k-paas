# K-PaaS Architecture Diagrams

This document visualizes the K-PaaS architecture using Mermaid diagrams, based on the [Architecture Documentation](ARCHITECTURE.md).

## 1. System Overview

High-level view of the K-PaaS platform on Kakao Cloud.

```mermaid
graph TB
    subgraph Internet
        User[User / Developer]
    end

    subgraph KakaoCloud ["Kakao Cloud - kr-central-2-a"]
        subgraph LoadBalancers [Load Balancers]
            MasterLB["Master LB - NLB L4"]
            WorkerLB["Worker LB - NLB L4"]
        end

        subgraph K8sCluster [K-PaaS Kubernetes Cluster]
            subgraph ControlPlane [Control Plane]
                Master1[Master-1]
                Master2[Master-2]
                Master3[Master-3]
            end

            subgraph WorkerNodes [Worker Nodes]
                Worker1[Worker-1]
                Worker2[Worker-2]
                Worker3[Worker-3]
            end
        end
    end

    User -->|HTTPS/6443| MasterLB
    User -->|HTTP/HTTPS| WorkerLB

    MasterLB -->|TCP 6443| ControlPlane
    WorkerLB -->|TCP 80/443| WorkerNodes

    ControlPlane -.->|Control| WorkerNodes
```

## 2. Network Architecture

Detailed network topology including VPC, Subnets, and IP allocations.

```mermaid
graph TB
    subgraph VPC ["VPC: kpaas-vpc (172.16.0.0/16)"]
        subgraph PublicSubnet ["Subnet: main_subnet (172.16.0.0/24)"]

            subgraph LBs [Load Balancers]
                MLB["Master LB<br>VIP: 172.16.0.54"]
                WLB["Worker LB<br>VIP: 172.16.0.88"]
            end

            subgraph Masters [Master Nodes - Fixed IPs]
                M1["Master-1<br>172.16.0.101"]
                M2["Master-2<br>172.16.0.102"]
                M3["Master-3<br>172.16.0.103"]
            end

            subgraph Workers [Worker Nodes - Fixed IPs]
                W1["Worker-1<br>172.16.0.111"]
                W2["Worker-2<br>172.16.0.112"]
                W3["Worker-3<br>172.16.0.113"]
            end

            subgraph ServiceIPs [Service IP Ranges]
                K8sSvc["K8s Services<br>10.233.0.0/18"]
                PodNet["Pod Network<br>10.233.64.0/18"]
                MetalLBPool["MetalLB Pool<br>172.16.0.210-250"]
            end
        end
    end

    Internet((Internet)) --> MLB
    Internet --> WLB

    MLB --> M1
    MLB --> M2
    MLB --> M3
    WLB --> W1
    WLB --> W2
    WLB --> W3
```

## 3. Service Architecture & Ingress

How external traffic reaches applications via Ingress Controller.

```mermaid
graph LR
    User((User)) -->|HTTPS| WLB[Worker LB]
    WLB -->|NodePort 31443| Ingress[Ingress Nginx]

    subgraph Services [K-PaaS Services]
        Ingress -->|portal.k-paas.io| Portal[CP-Portal]
        Ingress -->|harbor.k-paas.io| Harbor[Harbor Registry]
        Ingress -->|keycloak.k-paas.io| Keycloak[Keycloak IAM]
        Ingress -->|openbao.k-paas.io| OpenBao[OpenBao Secrets]
    end

    subgraph Backend [Backend Components]
        Portal --> K8sAPI[K8s API Server]
        Portal --> Keycloak
        Harbor --> Keycloak
        Harbor --> NFS[NFS Storage]
    end
```

## 4. Data Flow: Container Image Pull

The flow of a developer pulling a container image from Harbor.

```mermaid
sequenceDiagram
    participant Dev as Developer
    participant DNS as DNS
    participant WLB as Worker LB
    participant Ingress as Ingress Controller
    participant Harbor as Harbor Registry
    participant Keycloak as Keycloak
    participant Storage as NFS Storage

    Dev->>DNS: Resolve harbor.k-paas.io
    DNS-->>Dev: Worker LB Public IP

    Dev->>WLB: HTTPS Request Port 443
    Note over WLB: Forward to NodePort 31443
    WLB->>Ingress: TCP Connection

    Ingress->>Harbor: Route /v2/ request

    Harbor->>Keycloak: Validate Token/Auth
    Keycloak-->>Harbor: Token Valid

    Harbor->>Storage: Read Image Layers
    Storage-->>Harbor: Image Data

    Harbor-->>Dev: Image Layers Stream
```

## 5. Component Interaction

Relationships between key K-PaaS components.

```mermaid
classDiagram
    class CPPortal {
        +Management Console
        +User Management
        +Monitoring Dashboard
    }
    class Harbor {
        +Container Registry
        +Helm Chart Repo
        +Vulnerability Scan
    }
    class Keycloak {
        +Identity Provider
        +SSO Service
        +OIDC OAuth2
    }
    class OpenBao {
        +Secret Management
        +Encryption Service
    }
    class Kubernetes {
        +Container Orchestration
        +API Server
    }

    CPPortal --> Kubernetes : Manages Resources
    CPPortal --> Keycloak : Authenticates Users
    Harbor --> Keycloak : Authenticates Users
    Harbor --> OpenBao : Stores Secrets
    Kubernetes --> Harbor : Pulls Images
    Kubernetes --> OpenBao : Fetches Secrets
    Kubernetes --> Keycloak : OIDC Auth
```
