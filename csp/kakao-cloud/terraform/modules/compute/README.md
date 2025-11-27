# Compute Module

K-PaaS 배포를 위한 Master 및 Worker VM 인스턴스를 관리하는 모듈입니다.

## 리소스

- `kakaocloud_instance.master` - Master 노드 인스턴스 (Control Plane)
- `kakaocloud_instance.worker` - Worker 노드 인스턴스 (Data Plane)
- `kakaocloud_public_ip.master_ip` - Master 노드 Public IP
- `kakaocloud_public_ip.worker_ip` - Worker 노드 Public IP

## 사용 예제

```hcl
module "compute" {
  source = "./modules/compute"

  master_name          = "master"
  worker_name          = "worker"
  master_count         = 3
  worker_count         = 3
  image_name           = "Ubuntu 24.04"
  instance_flavor      = "t1i.xlarge"
  volume_size          = 200
  key_name             = "KPAAS_KEYPAIR"
  subnet_id            = module.network.subnet_id
  security_group_name  = module.security.security_group_name
  cloud_init_base64    = filebase64("cloud-init.yaml")
}
```

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| master_name | Master 노드 이름 접두사 | string | "master" |
| worker_name | Worker 노드 이름 접두사 | string | "worker" |
| master_count | Master 노드 수 | number | 3 |
| worker_count | Worker 노드 수 | number | 3 |
| image_name | OS 이미지 이름 | string | "Ubuntu 24.04" |
| instance_flavor | 인스턴스 사양 | string | "t1i.xlarge" |
| volume_size | 부트 볼륨 크기 (GB) | number | 200 |
| key_name | SSH 키페어 이름 | string | - |
| subnet_id | 인스턴스를 연결할 서브넷 ID | string | - |
| security_group_name | 적용할 보안 그룹 이름 | string | - |
| cloud_init_base64 | Base64 인코딩된 cloud-init 데이터 | string | - |

## Outputs

| Name | Description |
|------|-------------|
| master_instance_ids | Master 인스턴스 ID 목록 |
| master_private_ips | Master 사설 IP 목록 |
| master_public_ips | Master 공인 IP 목록 |
| worker_instance_ids | Worker 인스턴스 ID 목록 |
| worker_private_ips | Worker 사설 IP 목록 |
| worker_public_ips | Worker 공인 IP 목록 |
| master_count | Master 노드 수 |
| worker_count | Worker 노드 수 |

## 주의사항

- 인스턴스 생성 전 네트워크와 보안 그룹이 먼저 생성되어야 합니다.
- cloud-init 파일은 base64로 인코딩하여 전달해야 합니다.
- 인스턴스 사양(flavor)은 카카오클라우드에서 지원하는 것만 사용 가능합니다.
