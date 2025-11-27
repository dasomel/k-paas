# LoadBalancer Module

K-PaaS 배포를 위한 Master 및 Worker 로드밸런서를 관리하는 모듈입니다.

## 리소스

### Master Load Balancer (K8s API Server용)

| Name                                                        | Description             |
|-------------------------------------------------------------|-------------------------|
| kakaocloud_load_balancer.master_lb                          | Master 로드밸런서 (NLB)      |
| kakaocloud_public_ip.master_lb_ip                           | Master LB Public IP     |
| kakaocloud_load_balancer_listener.k8s_api                   | K8s API Listener (6443) |
| kakaocloud_load_balancer_listener.etcd                      | etcd Listener (2379)    |
| kakaocloud_load_balancer_target_group.masters               | K8s API 타겟 그룹           |
| kakaocloud_load_balancer_target_group.etcd                  | etcd 타겟 그룹              |
| kakaocloud_load_balancer_target_group_member.master_members | 타겟 멤버                   |

### Worker Load Balancer (Ingress용)
| Name                                                             | Description               |
|------------------------------------------------------------------|---------------------------|
| kakaocloud_load_balancer.worker_lb                               | Worker 로드밸런서 (NLB L4 DSR) |
| kakaocloud_public_ip.worker_lb_ip                                | Worker LB Public IP       |         
| kakaocloud_load_balancer_listener.http                           | HTTP Listener (80)        |  
| kakaocloud_load_balancer_listener.https                          | HTTPS Listener (443)      |
| kakaocloud_load_balancer_target_group.workers_http               | HTTP 타겟 그룹                |
| kakaocloud_load_balancer_target_group.workers_https              | HTTPS 타겟 그룹               |
| kakaocloud_load_balancer_target_group_member.worker_http_members | 타겟 멤버                     |

## 사용 예제

```hcl
module "loadbalancer" {
  source = "./modules/loadbalancer"

  master_lb_name                = "master-lb"
  worker_lb_name                = "worker-lb"
  availability_zone             = "kr-central-2-a"
  subnet_id                     = module.network.subnet_id
  master_private_ips            = module.compute.master_private_ips
  worker_private_ips            = module.compute.worker_private_ips
  master_instances_dependency   = module.compute.master_instances
  master_public_ips_dependency  = module.compute.master_public_ip_objects
  worker_instances_dependency   = module.compute.worker_instances
  worker_public_ips_dependency  = module.compute.worker_public_ip_objects
}
```

## Inputs

| Name                         | Description          | Type         | Default          |
|------------------------------|----------------------|--------------|------------------|
| master_lb_name               | Master LB 이름         | string       | "master-lb"      |
| worker_lb_name               | Worker LB 이름         | string       | "worker-lb"      |
| availability_zone            | 가용 영역                | string       | "kr-central-2-a" |
| subnet_id                    | 서브넷 ID               | string       | -                |
| master_private_ips           | Master 노드 사설 IP 목록   | list(string) | -                |
| worker_private_ips           | Worker 노드 사설 IP 목록   | list(string) | -                |
| master_instances_dependency  | Master 인스턴스 의존성      | any          | null             |
| master_public_ips_dependency | Master Public IP 의존성 | any          | null             |
| worker_instances_dependency  | Worker 인스턴스 의존성      | any          | null             |
| worker_public_ips_dependency | Worker Public IP 의존성 | any          | null             |

## Outputs

| Name                | Description              |
|---------------------|--------------------------|
| master_lb_id        | Master LB ID             |
| master_lb_vip       | Master LB VIP (내부)       |
| master_lb_public_ip | Master LB Public IP (외부) |
| worker_lb_id        | Worker LB ID             |
| worker_lb_vip       | Worker LB VIP (내부)       |
| worker_lb_public_ip | Worker LB Public IP (외부) |

## 주의사항

- 로드밸런서는 인스턴스 생성 후 생성되어야 합니다.
- Master LB는 NLB flavor를 사용합니다.
- Worker LB는 NLB_L4_DSR flavor를 사용합니다 (성능 최적화).
- 타겟 그룹 멤버는 인스턴스의 Private IP를 사용합니다.
