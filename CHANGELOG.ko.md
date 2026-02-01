# Changelog

K-PaaS 로컬 설치 자동화 도구 변경 이력

---

## [2.2.0] - 2026-01-24

### K-PaaS v1.7.0 지원

#### Added

##### ARM64 Portal 지원
- `ghcr.io/dasomel-k-pass` ARM64 Portal 이미지 지원
  - cp-portal-ui, cp-portal-api, cp-catalog-api, cp-metrics-api 등 전체 컴포넌트
  - 서비스명 변경 자동 매핑 (cp-portal-xxx → cp-xxx)
  - Ingress backend 서비스명 자동 패치

##### ARM64 Harbor 지원
- `ghcr.io/dasomel/goharbor` ARM64 Harbor 이미지 지원
  - registry-photon, harbor-registryctl 이미지 hotfix 자동 적용
  - `install_cert.sh` 스크립트 주입 및 권한 설정
  - Podman을 통한 이미지 빌드 및 Worker 노드 배포 자동화

##### 인프라 자동화
- Init container 방식 SSL 인증서 주입 (이미지 재빌드 불필요)
- Keycloak Bitnami Helm chart 배포 자동화 (기존 스크립트 스킵 처리)
- catalog-api config.env ConfigMap 자동 생성
- OpenBao unseal key 자동 관리

##### Kakao Cloud 배포
- `terraform-layered/` 3-Layer 구조 추가 (Network → LoadBalancer → Cluster)
- 고정 IP 기반 LB Target 설정 (172.16.0.101-103, 172.16.0.111-113)
- `deploy.sh` 통합 배포 스크립트
- CoreDNS custom hosts 설정 자동화

##### 표준프레임워크 샘플
- egovframe-web-sample 멀티 아키텍처 빌드 지원 (amd64/arm64)
- 컨테이너 이미지 서명 (cosign) 지원
- SBOM (SPDX) 생성 지원

#### Changed
- 설정 변수 통합 (`00.global_variable.sh`로 일원화)
- ARM64 분기 처리 스크립트 내 inline으로 통합
- migration-ui probe 설정 자동 패치 (port 8097, path /cpmigui)
- MariaDB 10.11 다운그레이드 (ARM64 호환성)
- cp-admin 인증 방식 mysql_native_password로 변경 (JDBC 호환성)
- Helm install → `helm upgrade --install` 멱등성 개선

#### Removed
- `scripts/variable/` 디렉토리 (미사용)
- `scripts/arm/helm/` 디렉토리 (스크립트에 통합)
- `scripts/arm/*.sh` hotfix 스크립트들 (스크립트에 통합)

---

## [2.1.0] - 2026-01-07

### K-PaaS v1.6.2 지원

#### Added
- ARM64 (Apple Silicon) 환경 지원
- Harbor ARM64 이미지 hotfix 스크립트
- Portal UI 인증서 hotfix 스크립트

#### Changed
- Vagrant Box dasomel/ubuntu-24.04 변경
- ARM64 이미지 지원 개선

---

## [2.0.0] - 2024-12-20

### K-PaaS v1.6.2 지원

#### Added
- ARM64 아키텍처 지원 추가
- VMware Desktop Provider 지원
- Ubuntu 24.04 (bento/ubuntu-24.04) 기본 이미지

#### Changed
- K-PaaS v1.5.2 → v1.6.2 업그레이드
- Vagrant Box 버전 업데이트

---

## [1.0.1] - 2024-09-15

### K-PaaS v1.5.2 지원

#### Changed
- K-PaaS v1.5.0 → v1.5.2 업그레이드
- 설치 스크립트 안정성 개선

#### Fixed
- kubectl 버전 변경 스크립트 제거

---

## [1.0.0] - 2024-09-08

### 최초 릴리즈

#### Added
- Vagrant 기반 K-PaaS 로컬 설치 자동화
- VirtualBox Provider 지원
- 6노드 클러스터 구성 (LB 2, Master 2, Worker 2)
- HAProxy + Keepalived 고가용성 로드밸런서
- Kubespray 기반 Kubernetes 설치
- K-PaaS Container Platform Portal 설치

---

## 버전 호환성

| 로컬 설치 도구 | K-PaaS CP | Kubernetes | Ubuntu | 아키텍처 |
|---------------|-----------|------------|--------|----------|
| 2.2.0 | v1.7.0 | v1.33.5 | 24.04 | amd64, arm64 |
| 2.1.0 | v1.6.2 | v1.31+ | 24.04 | amd64, arm64 |
| 2.0.0 | v1.6.2 | v1.30+ | 24.04 | amd64, arm64 |
| 1.0.1 | v1.5.2 | v1.28+ | 22.04 | amd64 |
| 1.0.0 | v1.5.0 | v1.28+ | 22.04 | amd64 |
