# K-PaaS Local Install

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
![code](https://img.shields.io/badge/Code-ShellScript-blue)
![version](https://img.shields.io/badge/version-1.0.0-blue)
[![member](https://img.shields.io/badge/Project-Member-brightgreen)](https://github.com/dasomel/k-paas?tab=readme-ov-file#developer)

> K-PaaS Local(PC) Install
 
![main.png](./docs/images/main.png)

## Description
- 로컬(Intel 기반 CPU)에서 K-PaaS를 구동하기 위한 Vagrant와 Virtualbox 기반의 ShellScript
- 기본적으로 모두 자동화되어 있음(실행시 모두 자동 설치)
- 로컬에서 K-PaaS 설치를 통한 사용자 접근성 및 이해도 향상
- 설치 과정에서 오류에 대한 트러블슈팅 안내
- K-PaaS 최신 버전(v1.5.1) 적용

## Glossary
- Vagrant
  - 가상 환경을 손쉽게 설정하고 관리하기 위한 도구
  - 가상 머신을 쉽게 생성하고, 프로비저닝1)하며, 관리
  - 개발 환경이나 테스트 환경을 빠르게 구축하고 공유
  - 가상화 기술을 기반으로 하며, 다양한 가상화 플랫폼을 지원
  - 개발자들은 Vagrant를 사용하여 프로젝트 간의 일관된 환경을 유지하고, 팀 간의 협업이 용이
- virtualbox
  - x86 가상화 소프트웨어
  - 이 소프트웨어는 다양한 운영 체제에서 동작하며, 가상머신을 생성하고 관리
  - 하나의 컴퓨터에서 여러 개의 가상머신을 실행
  - 다양한 운영 체제나 환경에서 소프트웨어를 테스트하거나 개발
  - 무료이며 오픈 소스로 제공되어 사용자들이 자유롭게 활용 가능
  - Oracle Corporation에 의해 개발되었으며, 다양한 운영 체제와 호환되는 특징
- Kubespray
  - Kubernetes를 손쉽게 배포하고 관리하기 위한 오픈 소스 도구
  - Ansible을 기반으로 하여 여러 대의 서버에 Kubernetes 클러스터를 배포하고 설정하는 작업을 자동화
  - 개발자나 시스템 관리자는 Kubernetes를 사용하여 컨테이너 기반의 어플리케이션을 효과적으로 관리 가능
  - 클러스터를 손쉽게 구성하고 필요에 따라 확장 가능
  - 다양한 환경에서 Kubernetes를 일관되게 배포하고 유지보수가 용이
  - Ansible을 통한 구성 파일을 사용하므로 사용자는 설정을 쉽게 변경하거나 다양한 환경에 맞게 조정 가능
  - Kubernetes를 더 쉽게 사용할 수 있도록 도와주는 유용한 도구
- Ansible
  - 오픈 소스 인프라 자동화 도구로, 서버의 프로비저닝, 설정 관리, 배포 등의 작업을 자동화하는 데 사용
  - 간단하고 가독성이 높은 YAML 형식의 구성 파일을 통해 작업을 정의하고, SSH를 통해 원격 서버에 명령을 전송하여 작업을 수행
  - 에이전트가 필요하지 않으며, 목표 서버에 Python이 설치되어야 함
  - 이를 통해 에이전트를 설치하거나 관리하지 않고도 간편하게 자동화 작업을 수행
  - 다양한 환경에서 사용 가능하며, 클라우드 환경부터 온프레미스 서버까지 다양한 인프라 자원을 효과적으로 관리
  - 개발자, 시스템 관리자, 데브옵스 엔지니어 등 다양한 역할의 사용자들에게 널리 사용되며, 자동화된 작업을 통해 인프라를 안정적이고 일관되게 유지가 용이


## Test device specifications
- Intel MacBook

## Installed Portal Demo
![demo_portal.gif](./docs/images/demo_portal.gif)

## Getting Started

### Installation
```shell
# ex: vagrant_20240607_201213.log
vagrant up &> ./logs/vagrant_$(date +%Y%m%d_%H%M%S).log
```
### VM stop
```shell
vagrant suspend
```
### VM destory
```shell
vagrant destroy -f
```

### Log
- vagrant
![log_vagrant.gif](./docs/images/log_vagrant.gif)
- platform
![log_platform.gif](./docs/images/log_platform.gif)

### Platform installation complete
```shell
vagrant@master01:~$ kubectl get po -A
NAMESPACE        NAME                                               READY   STATUS      RESTARTS      AGE
cp-portal        cp-portal-api-deployment-55ffb6495b-b285b          1/1     Running     0             19m
cp-portal        cp-portal-common-api-deployment-76887f945f-r5zwn   1/1     Running     0             19m
cp-portal        cp-portal-metric-api-deployment-6cb7ff679d-vqxcg   1/1     Running     0             19m
cp-portal        cp-portal-terraman-deployment-f84c47bd7-zjb4w      1/1     Running     0             23m
cp-portal        cp-portal-ui-deployment-7cf58c847c-xmcwq           1/1     Running     0             19m
default          nfs-pod-provisioner-5fdb9dd5d6-ld49k               1/1     Running     3 (38m ago)   39m
harbor           cp-harbor-chartmuseum-8456b8856b-7f9b9             1/1     Running     0             34m
harbor           cp-harbor-core-856df8bb99-r2dnq                    1/1     Running     0             34m
harbor           cp-harbor-database-0                               1/1     Running     3 (14m ago)   34m
harbor           cp-harbor-jobservice-59f674897b-n8j9p              1/1     Running     3 (32m ago)   34m
harbor           cp-harbor-notary-server-5f58f65769-kc242           1/1     Running     6 (14m ago)   34m
harbor           cp-harbor-notary-signer-5ffbfccc6c-nzxpg           1/1     Running     1 (33m ago)   34m
harbor           cp-harbor-portal-776646487f-dcrjz                  1/1     Running     0             34m
harbor           cp-harbor-redis-0                                  1/1     Running     0             34m
harbor           cp-harbor-registry-68899d8bfb-xvxgg                2/2     Running     0             34m
harbor           cp-harbor-trivy-0                                  1/1     Running     0             34m
ingress-nginx    ingress-nginx-admission-create-fc8dg               0/1     Completed   0             39m
ingress-nginx    ingress-nginx-admission-patch-zx5hq                0/1     Completed   1             39m
ingress-nginx    ingress-nginx-controller-6dc9c5fb7c-pf6mp          1/1     Running     0             39m
keycloak         cp-keycloak-667678f5bd-2qfxt                       1/1     Running     0             19m
keycloak         cp-keycloak-667678f5bd-x42z7                       1/1     Running     0             18m
kube-system      calico-kube-controllers-648dffd99-nth7x            1/1     Running     0             46m
kube-system      calico-node-f4r57                                  1/1     Running     0             47m
kube-system      calico-node-k2f4x                                  1/1     Running     0             47m
kube-system      calico-node-lxzqp                                  1/1     Running     0             47m
kube-system      calico-node-twvjn                                  1/1     Running     0             47m
kube-system      coredns-77f7cc69db-rx9g4                           1/1     Running     0             45m
kube-system      coredns-77f7cc69db-scqz9                           1/1     Running     0             45m
kube-system      dns-autoscaler-8576bb9f5b-fzxp6                    1/1     Running     0             45m
kube-system      kube-apiserver-master01                            1/1     Running     0             38m
kube-system      kube-apiserver-master02                            1/1     Running     0             38m
kube-system      kube-controller-manager-master01                   1/1     Running     2             49m
kube-system      kube-controller-manager-master02                   1/1     Running     3 (38m ago)   48m
kube-system      kube-proxy-4xfxk                                   1/1     Running     0             48m
kube-system      kube-proxy-5m6hk                                   1/1     Running     0             48m
kube-system      kube-proxy-6rtws                                   1/1     Running     0             48m
kube-system      kube-proxy-mkbwh                                   1/1     Running     0             48m
kube-system      kube-scheduler-master01                            1/1     Running     2 (38m ago)   49m
kube-system      kube-scheduler-master02                            1/1     Running     2 (42m ago)   48m
kube-system      metrics-server-bd6df7764-lllq6                     1/1     Running     0             44m
kube-system      nodelocaldns-2cm6z                                 1/1     Running     0             45m
kube-system      nodelocaldns-2w9pn                                 1/1     Running     0             45m
kube-system      nodelocaldns-976pm                                 1/1     Running     0             45m
kube-system      nodelocaldns-h8x4h                                 1/1     Running     0             45m
mariadb          cp-mariadb-0                                       1/1     Running     0             23m
metallb-system   controller-666f99f6ff-jgd4p                        1/1     Running     0             44m
metallb-system   speaker-dw6lt                                      1/1     Running     0             44m
metallb-system   speaker-fvh7b                                      1/1     Running     0             44m
metallb-system   speaker-tff9j                                      1/1     Running     0             44m
metallb-system   speaker-zrj6m                                      1/1     Running     0             44m
vault            cp-vault-0                                         1/1     Running     0             34m
vault            cp-vault-agent-injector-7b84c58f45-cmw4g           1/1     Running     0             34m
```

### Local(PC) setting
- Macbook, Linux
- File: /etc/hosts
```shell
sudo cat << EOF | sudo tee -a /etc/hosts
192.168.100.200 cluster-endpoint
192.168.100.201 k-paas.io
192.168.100.201 vault.k-paas.io
192.168.100.201 harbor.k-paas.io
192.168.100.201 keycloak.k-paas.io
192.168.100.201 portal.k-paas.io
EOF
```
- windows
- File: C:\Windows\System32\drivers\etc\hosts
- Run cmd as administrator
```shell
echo.192.168.100.200 cluster-endpoint>>   %SystemRoot%\system32\drivers\etc\hosts
echo.192.168.100.201 k-paas.io>>          %SystemRoot%\system32\drivers\etc\hosts
echo.192.168.100.201 vault.k-paas.io>>    %SystemRoot%\system32\drivers\etc\hosts
echo.192.168.100.201 harbor.k-paas.io>>   %SystemRoot%\system32\drivers\etc\hosts
echo.192.168.100.201 keycloak.k-paas.io>> %SystemRoot%\system32\drivers\etc\hosts
echo.192.168.100.201 portal.k-paas.io>>   %SystemRoot%\system32\drivers\etc\hosts
```

## Stack
- **Language**: Shellscript
- **Deploy**: Local NoteBook(Intel Macbook)

## Project Structure

```markdown
K-paas
├── docs
│   └── images
├── logs
└── scripts
    └── variable
```

| Directory | Note                        | Type       |
|-----------|-----------------------------|------------|
| docs      | document                    | .md        |
| images    | images, video               | .png, .gif |
| logs      | vagrant logs                | .log       |
| scripts   | vagrant install shellscript | .sh        |
| variable  | cp-cluster-vars.sh          | .sh        |

## Developer
*  **이기하** ([dasomel](https://github.com/dasomel))







