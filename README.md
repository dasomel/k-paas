# K-PaaS Lite

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
![code](https://img.shields.io/badge/Code-ShellScript-blue)
![version](https://img.shields.io/badge/version-2.2.0-blue)
[![member](https://img.shields.io/badge/Project-Member-brightgreen)](https://github.com/dasomel/k-paas?tab=readme-ov-file#developer)

English | [한국어](README.ko.md) | [Changelog](CHANGELOG.md)

![main.png](./docs/images/portal_main_1.6.2.png)

## Description
- Lightweight K-PaaS installation tool based on Vagrant (VirtualBox, VMware support / ARM CPU support)
- Fully automated deployment
- Improves user accessibility and understanding through simplified K-PaaS setup
- Provides troubleshooting guidance for errors during the installation process
- Applies the latest version of K-PaaS (v1.7.0)

## Glossary
- Vagrant
  - A tool for easily setting up and managing virtual environments
  - Quickly creates, provisions, and manages virtual machines
  - Enables rapid building and sharing of development or test environments
  - Based on virtualization technology, and supports various virtualization platforms
  - Developers can use Vagrant to maintain consistent environments between projects and facilitate team collaboration
- virtualbox
  - virtualization software
  - Operates on various operating systems and creates/manages virtual machines
  - Allows multiple virtual machines to run on a single computer
  - Useful for testing or developing software in different operating systems or environments
  - Free and open source, allowing users to utilize it freely
  - Developed by Oracle Corporation, and features compatibility with many operating systems
- VMware
  - Virtualization software, offering VMware Fusion Pro (macOS) and VMware Workstation Pro (Windows/Linux)
  - VMware Fusion supports virtualization on Apple Silicon (ARM64) Macs
  - Provides improved performance and stability compared to VirtualBox
  - Requires VMware Desktop Provider plugin for Vagrant integration
  - Free for all users (personal, educational, commercial) since November 2024, no license key required
- Kubespray
  - An open-source tool for easily deploying and managing Kubernetes
  - Automates the deployment and configuration of Kubernetes clusters on multiple servers using Ansible
  - Developers or system administrators can efficiently manage container-based applications with Kubernetes
  - Clusters can be easily configured and expanded as needed
  - Enables consistent deployment and maintenance of Kubernetes in various environments
  - Uses Ansible configuration files, making it easy for users to adjust settings or tailor to multiple environments
  - A useful tool that makes using Kubernetes much easier
- Ansible
  - An open-source infrastructure automation tool; automates server provisioning, configuration management, and deployment
  - Defines tasks with simple, readable YAML configuration files and executes commands on remote servers over SSH
  - Agentless; only requires Python to be installed on the target server
  - Allows simple automation without installing or managing agents
  - Usable in a wide variety of environments, from cloud to on-premises infrastructure
  - Widely used by developers, system administrators, DevOps engineers, etc. for keeping infrastructure stable and consistent through automation
    
## Test device specifications
- MacMini(ARM)

## Installed Portal Demo
![demo_portal.gif](./docs/images/demo_portal.gif)

## Getting Started

### Prerequisites

#### VirtualBox (x86/Intel)
```shell
# Install VirtualBox
brew install --cask virtualbox
```

#### VMware (ARM64/Apple Silicon)
```shell
# Install VMware Fusion
brew install --cask vmware-fusion

# Install Vagrant VMware plugin
vagrant plugin install vagrant-vmware-desktop
```

### Installation

#### VirtualBox
```shell
# ex: vagrant_20240607_201213.log
vagrant up &> ./logs/vagrant_$(date +%Y%m%d_%H%M%S).log
```

#### VMware
```shell
# Run with VMware provider
vagrant up --provider=vmware_desktop &> ./logs/vagrant_$(date +%Y%m%d_%H%M%S).log
```

### VM stop
```shell
vagrant suspend
```

### VM destroy
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
NAMESPACE        NAME                                                    READY   STATUS             RESTARTS         AGE
chaos-mesh       chaos-controller-manager-6648dff67b-8dv6w               1/1     Running            1 (25h ago)      26h
chaos-mesh       chaos-daemon-49qvk                                      1/1     Running            0                26h
chaos-mesh       chaos-daemon-8tshd                                      1/1     Running            0                26h
chaos-mesh       chaos-dashboard-58d8d8589c-tvsl5                        1/1     Running            0                26h
chaos-mesh       chaos-dns-server-6cbc94c77-q8mc4                        1/1     Running            0                26h
chartmuseum      chartmuseum-648968c7dd-n7cjg                            1/1     Running            0                26h
cp-portal        cp-portal-api-deployment-56b5c87fcd-295cs               1/1     Running            0                22h
cp-portal        cp-portal-catalog-api-deployment-6f94b7d5c-qmp9p        1/1     Running            0                23h
cp-portal        cp-portal-chaos-api-deployment-74f5955f8d-22697         1/1     Running            0                23h
cp-portal        cp-portal-chaos-collector-deployment-69f847bff9-9jc8k   1/1     Running            0                23h
cp-portal        cp-portal-common-api-deployment-7b48b54788-zk75r        1/1     Running            0                22h
cp-portal        cp-portal-metric-api-deployment-575f9d4df8-qvf85        1/1     Running            0                23h
cp-portal        cp-portal-terraman-deployment-db5544bb4-v6lcz           1/1     Running            0                23h
cp-portal        cp-portal-ui-deployment-788d99bb45-x8hn4                1/1     Running            0                21h
default          nfs-subdir-external-provisioner-59b6cdb74d-dkwlm        1/1     Running            3 (25h ago)      46h
harbor           harbor-core-547d8bcf7b-vhr5r                            1/1     Running            0                26h
harbor           harbor-jobservice-5db8b59574-hbn49                      1/1     Running            0                26h
harbor           harbor-portal-7c8cf785d6-h6bg4                          1/1     Running            0                26h
harbor           harbor-postgresql-0                                     1/1     Running            0                26h
harbor           harbor-redis-master-0                                   1/1     Running            1 (23h ago)      26h
harbor           harbor-registry-6fd978fbf5-nchs8                        2/2     Running            0                26h
harbor           harbor-trivy-0                                          1/1     Running            0                26h
ingress-nginx    ingress-nginx-admission-create-4k5cr                    0/1     Completed          0                46h
ingress-nginx    ingress-nginx-admission-patch-gfqdn                     0/1     Completed          0                46h
ingress-nginx    ingress-nginx-controller-74f695ff79-mp5xx               1/1     Running            0                46h
keycloak         keycloak-0                                              1/1     Running            0                21h
keycloak         keycloak-1                                              1/1     Running            0                21h
kube-system      calico-kube-controllers-695788f969-6kp65                1/1     Running            27 (23h ago)     46h
kube-system      calico-node-6m8st                                       1/1     Running            0                46h
kube-system      calico-node-jlh7j                                       1/1     Running            1                46h
kube-system      calico-node-s2nqb                                       1/1     Running            0                46h
kube-system      calico-node-zvlsr                                       1/1     Running            1                46h
kube-system      coredns-dbd95956c-mp6k4                                 1/1     Running            0                20h
kube-system      coredns-dbd95956c-stbd5                                 1/1     Running            0                20h
kube-system      dns-autoscaler-846b5fbd88-pvvfg                         1/1     Running            0                46h
kube-system      kube-apiserver-master01                                 1/1     Running            30 (23h ago)     46h
kube-system      kube-apiserver-master02                                 1/1     Running            29               46h
kube-system      kube-controller-manager-master01                        1/1     Running            5                46h
kube-system      kube-controller-manager-master02                        1/1     Running            4                46h
kube-system      kube-proxy-qn8rn                                        1/1     Running            0                46h
kube-system      kube-proxy-r78kt                                        1/1     Running            0                46h
kube-system      kube-proxy-rbvmt                                        1/1     Running            1                46h
kube-system      kube-proxy-zw65x                                        1/1     Running            1                46h
kube-system      kube-scheduler-master01                                 1/1     Running            5                46h
kube-system      kube-scheduler-master02                                 1/1     Running            3                46h
kube-system      metrics-server-65765bb6cf-qtzdb                         1/1     Running            0                46h
kube-system      nodelocaldns-8vmk7                                      0/1     CrashLoopBackOff   48 (2m53s ago)   46h
kube-system      nodelocaldns-9pnm4                                      0/1     CrashLoopBackOff   49 (2m32s ago)   46h
kube-system      nodelocaldns-9s4z7                                      1/1     Running            0                46h
kube-system      nodelocaldns-zccff                                      1/1     Running            0                46h
kyverno          kyverno-admission-controller-7b74bfcfcb-gtjjx           1/1     Running            25 (23h ago)     46h
kyverno          kyverno-background-controller-7ff58cc7cb-sdgdg          1/1     Running            3 (25h ago)      46h
kyverno          kyverno-cleanup-controller-6999cc56d9-s4qvk             1/1     Running            25 (23h ago)     46h
kyverno          kyverno-reports-controller-64d994cdc5-nxb6n             1/1     Running            3 (25h ago)      46h
mariadb          mariadb-0                                               1/1     Running            0                26h
metallb-system   controller-68cccbf98c-8s2m9                             1/1     Running            2 (46h ago)      46h
metallb-system   speaker-2kzd8                                           1/1     Running            0                46h
metallb-system   speaker-5ngd9                                           1/1     Running            1                46h
metallb-system   speaker-78fx7                                           1/1     Running            2 (23h ago)      46h
metallb-system   speaker-shhv6                                           1/1     Running            0                46h
openbao          openbao-0                                               1/1     Running            0                26h
openbao          openbao-agent-injector-6567764cc9-rx54t                 1/1     Running            0                26h
```

### Local(PC) setting
- MacOS, Linux
- File: /etc/hosts
```shell
sudo cat << EOF | sudo tee -a /etc/hosts
192.168.100.200 cluster-endpoint
192.168.100.201 k-paas.io
192.168.100.201 openbao.k-paas.io
192.168.100.201 harbor.k-paas.io
192.168.100.201 keycloak.k-paas.io
192.168.100.201 portal.k-paas.io
192.168.100.201 chartmuseum.k-paas.io
EOF
```
- windows
- File: C:\Windows\System32\drivers\etc\hosts
- Run cmd as administrator
```shell
echo.192.168.100.200 cluster-endpoint>>    %SystemRoot%\system32\drivers\etc\hosts
echo.192.168.100.201 k-paas.io>>           %SystemRoot%\system32\drivers\etc\hosts
echo.192.168.100.201 openbao.k-paas.io>>   %SystemRoot%\system32\drivers\etc\hosts
echo.192.168.100.201 harbor.k-paas.io>>    %SystemRoot%\system32\drivers\etc\hosts
echo.192.168.100.201 keycloak.k-paas.io>>  %SystemRoot%\system32\drivers\etc\hosts
echo.192.168.100.201 portal.k-paas.io>>    %SystemRoot%\system32\drivers\etc\hosts
echo.192.168.100.201 chartmuseum.k-paas.io>> %SystemRoot%\system32\drivers\etc\hosts
```

## Stack
- **Language**: Shellscript
- **Deploy**: Local PC

## Project Structure

```markdown
K-paas
├── docs
│   └── images
├── logs
├── scripts
├── egovframe
│   └── egovframe-web-sample
└── csp
    └── kakao-cloud
```

| Directory | Note | Type |
|-----------|------|------|
| docs | documentation | .md |
| images | images, video | .png, .gif |
| logs | vagrant logs | .log |
| scripts | installation shell scripts | .sh |
| egovframe | standard framework samples | Dockerfile |
| csp | cloud service provider deployments | .tf |

## Cloud Deployment

### Kakao Cloud

In addition to local Vagrant deployment, K-PaaS can be deployed on [Kakao Cloud](https://cloud.kakao.com) using Terraform.

#### Features
- 3-Layer Terraform architecture (Network → LoadBalancer → Cluster)
- 6-node HA cluster (3 Masters + 3 Workers)
- Network Load Balancer for API Server and Ingress
- Automated K-PaaS Container Platform installation

#### Quick Start
```shell
cd csp/kakao-cloud/terraform-layered

# Configure variables
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars

# Deploy
./deploy.sh
```

#### Cluster Specifications
| Component | Spec | Count |
|-----------|------|-------|
| Master | t1i.xlarge (4 vCPU, 16GB) | 3 |
| Worker | t1i.xlarge (4 vCPU, 16GB) | 3 |
| Master LB | Network Load Balancer (L4) | 1 |
| Worker LB | Network Load Balancer (L4) | 1 |

For detailed documentation, see [csp/kakao-cloud/README.md](csp/kakao-cloud/terraform/README.md).

## Founder
*  **Kiha Lee** ([dasomel](https://github.com/dasomel))

## Acknowledgements
This project has been further developed thanks to the support of [Kakao Enterprise](https://kakaoenterprise.com).
In particular, we would like to express our deep gratitude for the following support:
* Provision of cloud resources 





