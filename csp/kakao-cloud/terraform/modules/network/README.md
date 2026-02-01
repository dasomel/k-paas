# Network Module

K-PaaS 배포를 위한 네트워크 인프라를 관리하는 모듈입니다.

## 리소스

- `kakaocloud_vpc` - VPC 생성
- `kakaocloud_subnet` - 메인 서브넷 생성

## 사용 예제

```hcl
module "network" {
  source = "./modules/network"

  vpc_name              = "test-kpaas"
  vpc_cidr              = "172.16.0.0/16"
  subnet_name           = "main_subnet"
  subnet_cidr           = "172.16.0.0/24"
  availability_zone     = "kr-central-2-a"
}
```

## Inputs

| Name              | Description | Type   | Default          |
|-------------------|-------------|--------|------------------|
| vpc_name          | VPC 이름      | string | "test-kpaas"     |
| vpc_cidr          | VPC CIDR 블록 | string | "172.16.0.0/16"  |
| subnet_name       | 서브넷 이름      | string | "main_subnet"    |
| subnet_cidr       | 서브넷 CIDR 블록 | string | "172.16.0.0/24"  |
| availability_zone | 가용 영역       | string | "kr-central-2-a" |

## Outputs

| Name              | Description |
|-------------------|-------------|
| vpc_id            | VPC ID      |
| vpc_cidr          | VPC CIDR 블록 |
| subnet_id         | 서브넷 ID      |
| subnet_cidr       | 서브넷 CIDR 블록 |
| availability_zone | 가용 영역       |

## 주의사항

- VPC 생성 시 약 5분 이상 소요될 수 있습니다.
- VPC 삭제 시 연결된 모든 리소스를 먼저 삭제해야 합니다.

## Known Issues

### Kakao Cloud Provider v0.2.0 Validation Bug

카카오 클라우드 프로바이더 v0.2.0에는 `kakaocloud_vpc` 리소스의 `name`, `cidr_block`, `subnet` 속성에서 Terraform 변수를 사용할 때 검증 오류가 발생하는 버그가 있습니다.

**증상:**
- `Cidr_block is not valid`
- `Subnet cidr_block is not valid`
- `Subnet cidr_block is not within parent`

**해결 방법:**
현재 이 모듈에서는 VPC 리소스의 해당 속성들을 하드코딩하여 사용하고 있습니다. 만약 다른 값이 필요한 경우 `modules/network/main.tf` 파일에서 직접 수정해야 합니다.

**영향을 받는 속성:**

| Name                      | Temporary workaround  |
|---------------------------|-----------------------|
| kakaocloud_vpc.name       | "test-kpaas"로 하드코딩    |
| kakaocloud_vpc.cidr_block | "172.16.0.0/16"로 하드코딩 |
| kakaocloud_vpc.subnet     | 서브넷 블록 전체가 하드코딩됨      |

**영향을 받지 않는 리소스:**
- `kakaocloud_subnet` 리소스는 정상적으로 변수 사용 가능

이 문제는 프로바이더 버그로, 향후 버전에서 수정될 것으로 예상됩니다.
