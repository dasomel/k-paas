# K-PaaS on Kakao Cloud - Documentation

[English](README.md) | 한국어

이 디렉토리에는 K-PaaS Kakao Cloud 배포 관련 문서가 포함되어 있습니다.

## 문서 목록

### 시작하기

| 문서 | 설명 |
|------|------|
| [../terraform/README.md](../terraform/README.md) | 메인 가이드: 빠른 시작, 배포, 설정 |
| [k-paas.md](k-paas.md) | K-PaaS 설치 요구사항 (인스턴스 사양) |

### 아키텍처

| 문서 | 설명 |
|------|------|
| [ARCHITECTURE.md](ARCHITECTURE.md) | 상세 아키텍처 및 설계 문서 |
| [ARCHITECTURE_DIAGRAMS.md](ARCHITECTURE_DIAGRAMS.md) | 아키텍처 다이어그램 |
| [PROJECT_ANALYSIS.md](PROJECT_ANALYSIS.md) | 프로젝트 분석 문서 |

### 설치 후 작업

| 문서 | 설명 |
|------|------|
| [README_POST_INSTALL_FIXES.md](README_POST_INSTALL_FIXES.md) | 포스트 설치 수정 가이드 |
| [POST_INSTALL_FIXES_SUMMARY.md](POST_INSTALL_FIXES_SUMMARY.md) | 포스트 설치 요약 |
| [SCRIPT_TEMPLATES.md](SCRIPT_TEMPLATES.md) | 스크립트 템플릿 설명 |

## 버전 정보

| 컴포넌트 | 버전 |
|----------|------|
| K-PaaS | 1.7.0 |
| Kubernetes | v1.33.5 |
| CRI-O | v1.33.5 |
| Ubuntu | 24.04 LTS |
| Terraform Provider | kakaocloud v0.2.0 |

## 배포 구성

| 노드 타입 | 개수 | 사양 |
|----------|------|------|
| Master | 3개 | t1i.xlarge (4 vCPU, 16GB) |
| Worker | 3개 | t1i.xlarge (4 vCPU, 16GB) |
| Load Balancer | 2개 | Master LB, Worker LB |

## 주요 서비스

| 서비스 | URL | 설명 |
|--------|-----|------|
| CP-Portal | https://portal.k-paas.io | K-PaaS 관리 포털 |
| Harbor | https://harbor.k-paas.io | 컨테이너 레지스트리 |
| Keycloak | https://keycloak.k-paas.io | 인증 서버 |
| OpenBao | https://openbao.k-paas.io | Secret 관리 |

## 관련 링크

- [K-PaaS GitHub](https://github.com/K-PaaS)
- [Kakao Cloud Console](https://console.kakaocloud.io)
- [Terraform Kakao Cloud Provider](https://registry.terraform.io/providers/kakaoenterprise/kakaocloud)
