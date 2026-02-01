# Account

서비스 접속 계정 정보

## 접속 정보

| 서비스 | URL | ID | PW | 비고 |
|--------|-----|----|----|------|
| Portal | https://portal.k-paas.io | admin | admin | Container Platform UI |
| Harbor | https://harbor.k-paas.io | admin | Harbor12345 | Container Registry |
| Keycloak | https://keycloak.k-paas.io/admin/cp-realm/console/ | admin | admin | SSO (CP Realm) |
| ChartMuseum | https://chartmuseum.k-paas.io | - | - | Helm Repository |

## Keycloak 접속

### CP Realm (권장)
- **URL**: https://keycloak.k-paas.io/admin/cp-realm/console/
- **계정**: admin / admin
- Container Platform 사용자 관리
- 이 계정을 사용하세요

### Master Realm
- **URL**: https://keycloak.k-paas.io/admin/master/console/
- Bitnami Helm chart에서 Master Realm admin 계정 생성 안 됨
- CP 운영에는 불필요

## OpenBao (Secrets)

### 토큰 획득
```bash
# Secret에서 토큰 조회
kubectl get secret openbao-unseal-keys -n openbao -o jsonpath='{.data.root_token}' | base64 -d

# 또는 설치 시 생성된 파일
cat ~/workspace/container-platform/cp-portal-deployment/secmg/root-token
```

### 웹 UI 접속
- **URL**: http://openbao.k-paas.io (Ingress 설정 시)
- **Token**: 위에서 획득한 root_token 사용
- Token 유효기간: 24시간 (갱신 가능)

## MariaDB

```bash
# 접속
kubectl exec -it -n mariadb mariadb-0 -- mariadb -uroot -pcpAdmin!12345

# 또는 cp-admin 계정
kubectl exec -it -n mariadb mariadb-0 -- mariadb -ucp-admin -pcpAdmin!12345
```

### 데이터베이스 목록
- `keycloak` - Keycloak 데이터
- `cp_portal` - Portal 데이터
- `cp_terraman` - Terraman 데이터

## Harbor Robot Account

자동 생성되는 로봇 계정:
```bash
# 계정 정보 확인
source ~/workspace/container-platform/cp-portal-deployment/script/cp-portal-vars.sh
echo "Username: $REPOSITORY_USERNAME"
echo "Password: $REPOSITORY_PASSWORD"
```
