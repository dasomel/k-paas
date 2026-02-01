# Troubleshooting

## Pod 상태 문제

### CrashLoopBackOff

**증상**: Pod가 반복적으로 재시작됨

```bash
# 로그 확인
kubectl logs -n <namespace> <pod-name>
kubectl logs -n <namespace> <pod-name> --previous

# 상세 이벤트
kubectl describe pod -n <namespace> <pod-name>
```

**일반적인 원인**:
- 애플리케이션 설정 오류
- 의존 서비스 연결 실패 (DB, 외부 API)
- 리소스 부족 (OOMKilled)

### ImagePullBackOff

**증상**: 이미지를 가져올 수 없음

```bash
# 이미지 확인
kubectl describe pod -n <namespace> <pod-name> | grep -A5 "Events"

# 레지스트리 인증 확인
kubectl get secret -n <namespace>
```

**해결**:
```bash
# 이미지 수동 pull (노드에서)
sudo podman pull <image-name>

# imagePullPolicy 확인
kubectl get deployment -n <namespace> <deploy-name> -o yaml | grep imagePullPolicy
```

### Pending

**증상**: Pod가 스케줄되지 않음

```bash
kubectl describe pod -n <namespace> <pod-name>
```

**일반적인 원인**:
- 노드 리소스 부족
- PVC 바인딩 대기
- NodeSelector/Affinity 불일치

---

## 네트워크 문제

### DNS 해석 실패

**증상**: 서비스 이름으로 연결 안 됨

```bash
# DNS 테스트
kubectl run -it --rm debug --image=busybox -- nslookup kubernetes.default

# CoreDNS 상태
kubectl get pods -n kube-system -l k8s-app=kube-dns
kubectl logs -n kube-system -l k8s-app=kube-dns
```

### Calico CNI 오류

**증상**: Pod 네트워크 생성 실패

```
plugin type="calico" failed (add): error getting ClusterInformation: Unauthorized
```

**해결**:
```bash
# VM 재시작
vagrant reload

# 또는 kubelet 재시작
sudo systemctl restart kubelet
```

### CoreDNS Loop 감지

**증상**: CoreDNS가 loop 감지로 종료

```
Loop detected for zone "."
```

**해결**:
```bash
# kube-apiserver bind-address 변경
LOCAL_IP=$(hostname -i | awk '{print $3}')
sudo sed -i 's/bind-address=0.0.0.0/bind-address='"$LOCAL_IP"'/g' /etc/kubernetes/manifests/kube-apiserver.yaml

sudo systemctl restart kubelet
```

---

## Harbor 문제

### 이미지 Push/Pull 실패

**증상**: Harbor 연결 또는 인증 실패

```bash
# Harbor 로그인
source ~/workspace/container-platform/cp-portal-deployment/script/cp-portal-vars.sh
sudo podman login harbor.k-paas.io --username $REPOSITORY_USERNAME --password $REPOSITORY_PASSWORD --tls-verify=false

# 이미지 Push
sudo podman push harbor.k-paas.io/cp-portal-repository/<image>:latest --tls-verify=false
```

### Harbor Database 문제

**증상**: harbor-database pod 오류

```bash
# StatefulSet 패치
kubectl patch statefulset harbor-database -n harbor --type='json' \
  -p='[{"op": "remove", "path": "/spec/template/spec/containers/0/volumeMounts/1"}]'

# 재시작
kubectl rollout restart statefulset harbor-database -n harbor
```

---

## OpenBao (Vault) 문제

### Sealed 상태

**증상**: OpenBao pod가 0/1 Ready

```bash
# 상태 확인
kubectl exec -n openbao openbao-0 -- bao status

# Unseal (저장된 키 사용)
UNSEAL_KEY=$(kubectl get secret openbao-unseal-keys -n openbao -o jsonpath='{.data.unseal_key_1}' | base64 -d)
kubectl exec -n openbao openbao-0 -- bao operator unseal $UNSEAL_KEY
```

### Unseal Key 분실

**증상**: Unseal key를 찾을 수 없음

```bash
# 설치 시 생성된 파일 확인
cat ~/workspace/container-platform/cp-portal-deployment/secmg/unseal-key
cat ~/workspace/container-platform/cp-portal-deployment/secmg/root-token
```

---

## Keycloak 문제

### DB 연결 실패

**증상**: Keycloak이 MariaDB에 연결 못함

```bash
# MariaDB 상태 확인
kubectl get pods -n mariadb
kubectl logs -n mariadb mariadb-0

# 연결 테스트
kubectl exec -n mariadb mariadb-0 -- mariadb -ucp-admin -p'cpAdmin!12345' -e "SHOW DATABASES;"
```

### OIDC Endpoint 오류

**증상**: Portal UI가 Keycloak에 연결 못함

```bash
# Keycloak 엔드포인트 테스트
curl -sk https://keycloak.k-paas.io/realms/cp-realm/.well-known/openid-configuration

# Ingress 확인
kubectl get ingress -n keycloak
```

---

## Portal UI 문제

### SSL 인증서 오류

**증상**: PKIX path building failed

```
unable to find valid certification path to requested target
```

**해결**: Init container로 인증서 주입 (06 스크립트에서 자동 처리)

```bash
# 수동 재시작
kubectl rollout restart deployment cp-portal-ui-deployment -n cp-portal
```

### Mixed Content 오류

**증상**: 브라우저에서 HTTPS/HTTP 혼합 콘텐츠 차단

**해결**: ConfigMap에서 API URI를 HTTPS로 변경
```bash
kubectl patch configmap cp-portal-configmap -n cp-portal --type=merge -p '{
  "data": {
    "CP_PORTAL_API_URI": "https://portal.k-paas.io/cpapi"
  }
}'
```

---

## VM 문제

### VirtualBox 네트워크 오류

**증상**: VM 간 네트워크 통신 실패

```bash
# VirtualBox 네트워크 재시작 (Host에서)
sudo /Library/Application\ Support/VirtualBox/LaunchDaemons/VirtualBoxStartup.sh restart

# Host-Only Network 확인
VBoxManage list hostonlyifs
```

### VMware 네트워크 오류

**증상**: VM이 IP를 받지 못함

```bash
# VMware 네트워크 서비스 재시작 (Host에서)
sudo /Applications/VMware\ Fusion.app/Contents/Library/vmnet-cli --stop
sudo /Applications/VMware\ Fusion.app/Contents/Library/vmnet-cli --start
```

---

## 리소스 부족

### 메모리 부족 (OOMKilled)

**증상**: Pod가 OOMKilled로 종료

```bash
# 노드 리소스 확인
kubectl top nodes
kubectl describe node <node-name> | grep -A5 "Allocated resources"

# Pod 리소스 사용량
kubectl top pods -n <namespace>
```

### 디스크 부족

**증상**: Pod 생성 실패, 이미지 Pull 실패

```bash
# 노드 디스크 확인 (노드에서)
df -h

# 미사용 이미지 정리
sudo podman image prune -a
```

---

## 로그 수집

### 전체 클러스터 상태
```bash
kubectl get nodes -o wide
kubectl get pods -A
kubectl get events -A --sort-by='.lastTimestamp'
```

### 특정 컴포넌트 디버깅
```bash
# kubelet
sudo journalctl -xfeu kubelet --since "10 minutes ago"

# crio
sudo journalctl -xfeu crio --since "10 minutes ago"

# 특정 Pod의 모든 컨테이너 로그
kubectl logs -n <namespace> <pod-name> --all-containers
```
