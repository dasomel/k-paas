# Provisioner Module

K-PaaS 배포를 위한 자동 프로비저닝을 관리하는 모듈입니다. 템플릿에서 설치 스크립트를 생성하고 Master-1 노드에 배포합니다.

## 리소스

### Local Files (Template Rendering)
- `local_file.cp_cluster_vars` - 클러스터 변수 설정 스크립트
- `local_file.global_variable` - 전역 변수 설정 스크립트
- `local_file.master_nfs_server` - NFS 서버 설정 스크립트
- `local_file.master_ssh_setting` - SSH 키 배포 스크립트
- `local_file.all_common_setting` - 공통 설정 스크립트
- `local_file.master_install_kpaas` - K-PaaS 설치 스크립트
- `local_file.master_install_portal` - Portal 설치 스크립트

### Null Resource (Provisioning)
- `null_resource.provision_master1` - Master-1 노드 프로비저닝

## 사용 예제

```hcl
module "provisioner" {
  source = "./modules/provisioner"

  master_count         = 3
  worker_count         = 3
  master_private_ips   = module.compute.master_private_ips
  master_public_ips    = module.compute.master_public_ips
  worker_private_ips   = module.compute.worker_private_ips
  master_lb_vip        = module.loadbalancer.master_lb_vip
  master_lb_public_ip  = module.loadbalancer.master_lb_public_ip
  worker_lb_vip        = module.loadbalancer.worker_lb_vip
  worker_lb_public_ip  = module.loadbalancer.worker_lb_public_ip
  metallb_ip_range     = "172.16.0.210-172.16.0.250"
  ingress_nginx_ip     = "172.16.0.201"
  terraform_dir        = path.module
  generated_dir        = "${path.module}/generated"
  ssh_key_path         = "./KPAAS_KEYPAIR.pem"
  auto_install_kpaas   = true
  master_lb_dependency = module.loadbalancer.master_lb
}
```

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| master_count | Master 노드 수 | number | - |
| worker_count | Worker 노드 수 | number | - |
| master_private_ips | Master 사설 IP 목록 | list(string) | - |
| master_public_ips | Master 공인 IP 목록 | list(string) | - |
| worker_private_ips | Worker 사설 IP 목록 | list(string) | - |
| master_lb_vip | Master LB VIP | string | - |
| master_lb_public_ip | Master LB 공인 IP | string | - |
| worker_lb_vip | Worker LB VIP | string | - |
| worker_lb_public_ip | Worker LB 공인 IP | string | - |
| metallb_ip_range | MetalLB IP 범위 | string | "172.16.0.210-172.16.0.250" |
| ingress_nginx_ip | Ingress Nginx IP | string | "172.16.0.201" |
| portal_domain | Portal 도메인 | string | "k-paas.io" |
| terraform_dir | Terraform 디렉토리 | string | - |
| generated_dir | 생성된 스크립트 디렉토리 | string | - |
| ssh_key_path | SSH 키 경로 | string | - |
| auto_install_kpaas | 자동 설치 여부 | bool | true |
| master_lb_dependency | Master LB 의존성 | any | null |


## Outputs

| Name | Description |
|------|-------------|
| provisioner_status | 프로비저닝 상태 및 설치 정보 |
| generated_scripts | 생성된 스크립트 파일 목록 |

## 프로비저닝 프로세스

1. **템플릿 렌더링**: Terraform 변수를 사용하여 설치 스크립트 생성
2. **스크립트 업로드**: Master-1 노드에 생성된 스크립트 전송
3. **자동 설치 실행**: 백그라운드에서 K-PaaS 설치 시작
4. **로그 모니터링**: `/home/ubuntu/kpaas_install.log` 파일 확인

## 설치 단계

자동 설치 시 다음 단계가 순차적으로 실행됩니다:

1. 공통 설정 (01.all_common_setting.sh)
2. NFS 서버 설정 (03.master_nfs_server.sh)
3. SSH 키 배포 (04.master_ssh_setting.sh)
4. K-PaaS 설치 (05.master_install_k-pass.sh)
5. Portal 설치 (06.master_install_k-pass_portal.sh)

## 주의사항

- 프로비저닝은 모든 인프라 리소스가 생성된 후 실행됩니다.
- SSH 키 파일이 올바른 경로에 존재해야 합니다.
- 자동 설치는 백그라운드에서 실행되며 20-40분 소요됩니다.
- 설치 로그는 Master-1의 `/home/ubuntu/kpaas_install.log`에서 확인 가능합니다.
