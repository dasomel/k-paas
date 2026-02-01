# Troubleshooting Scripts

배포 후 문제 발생 시 수동으로 실행하는 트러블슈팅 스크립트입니다.

## 스크립트 목록

| 스크립트 | 용도 |
|----------|------|
| `07.fix_harbor_certificate.sh` | Worker 노드에 Harbor 자체 서명 인증서 설정 |
| `08.fix_coredns_hostaliases.sh` | Pod 내 DNS 해결을 위한 hostAliases 패치 |
| `09.regenerate_apiserver_certificate.sh` | Master LB Public IP 포함 API Server 인증서 재생성 |
| `10.fix_cp-cert-setup-daemonset.sh` | cert-setup DaemonSet 수정 |

## 사용 방법

1. Master 노드에 SSH 접속
2. 스크립트를 Master 노드로 복사
3. `00.global_variable.sh` 변수 설정 확인
4. 스크립트 실행

```bash
# 예시: Harbor 인증서 설정
scp 07.fix_harbor_certificate.sh ubuntu@master01:/home/ubuntu/scripts/
ssh ubuntu@master01
cd /home/ubuntu/scripts
bash 07.fix_harbor_certificate.sh
```

## 참고 문서

- [SCRIPT_TEMPLATES.md](../../../docs/SCRIPT_TEMPLATES.md)
- [README_POST_INSTALL_FIXES.md](../../../docs/README_POST_INSTALL_FIXES.md)
