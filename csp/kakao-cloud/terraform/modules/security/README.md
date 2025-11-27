# Security Module

K-PaaS 배포를 위한 보안 그룹을 관리하는 모듈입니다.

## 리소스

- `kakaocloud_security_group` - K8s 클러스터용 보안 그룹 생성

## 포함된 보안 규칙

### Ingress 규칙
| Port        | Type      | 구분     | Purpose                    |
|-------------|-----------|----------|----------------------------|
| 22          | external  | ssh      | [외부 접속 허용] Allow external SSH access      |
| 111         | internal  | nfs rpcbind | [내부망 통신] Internal NFS rpcbind communication    |
| 179         | internal  | calico bgp | [내부망 통신] Internal Calico BGP communication     |
| 2049        | internal  | nfs      | [내부망 통신] Internal NFS communication            |
| 2379-2380   | internal  | etcd     | [내부망 통신] Internal etcd communication           |
| 4789        | internal  | calico vxlan | [내부망 통신] Internal Calico VXLAN communication   |
| 80          | external  | http     | [외부 접속 허용] Allow external HTTP access         |
| 443         | external  | https    | [외부 접속 허용] Allow external HTTPS access        |
| 6443        | external  | k8s api  | [외부 접속 허용] Allow external Kubernetes API access |
| 10250       | internal  | kubelet  | [내부망 통신] Internal Kubelet communication        |
| 10251-10252 | internal  | scheduler/controller | [내부망 통신] Internal Scheduler/Controller communication |
| 30000-32767 | external  | nodeport | [외부 접속 허용] Allow external NodePort access     |
| ICMP        | external  | icmp     | [외부 접속 허용] Allow external ICMP traffic        |


### Egress 규칙
- **ALL**: 모든 아웃바운드 트래픽 허용

## 사용 예제

```hcl
module "security" {
  source = "./modules/security"

  security_group_name = "kpaas-security-group"
  vpc_cidr            = "172.16.0.0/16"
}
```

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| security_group_name | 보안 그룹 이름 | string | - |
| description | 보안 그룹 설명 | string | "K-PaaS Terraform managed security group" |
| vpc_cidr | VPC CIDR (내부 트래픽 규칙용) | string | "172.16.0.0/16" |

## Outputs

| Name | Description |
|------|-------------|
| security_group_id | 보안 그룹 ID |
| security_group_name | 보안 그룹 이름 |

## 주의사항

- 보안 그룹은 VM 인스턴스 생성 전에 먼저 생성되어야 합니다.
- 내부망 규칙은 VPC CIDR을 기반으로 설정됩니다.
- 운영 환경에서는 SSH 접속 IP 제한을 권장합니다.
