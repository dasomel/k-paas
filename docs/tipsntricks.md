# Tips & Tricks

## SSH 접속

### Vagrant SSH
```bash
vagrant ssh master01
vagrant ssh worker01
```

### 직접 SSH
```bash
# SSH 키 캐시 초기화 (IP 재사용 시)
ssh-keygen -R 192.168.100.101

# 접속 (비밀번호: vagrant)
ssh vagrant@192.168.100.101  # master01
ssh vagrant@192.168.100.102  # master02
ssh vagrant@192.168.100.111  # worker01
ssh vagrant@192.168.100.112  # worker02
```

## 로그 확인

### 설치 로그
```bash
# Kubespray 설치 로그
tail -f /home/vagrant/cp-deployment/standalone/deploy-result.log

# Portal 설치 로그
tail -f /home/vagrant/workspace/container-platform/cp-portal-deployment/script/deploy-portal-result.log
```

### Pod 로그
```bash
# 특정 Pod
kubectl logs -n cp-portal deploy/cp-portal-ui-deployment

# 실시간 로그
kubectl logs -n cp-portal deploy/cp-portal-ui-deployment -f

# 이전 컨테이너 로그 (재시작 후)
kubectl logs -n cp-portal deploy/cp-portal-ui-deployment --previous
```

### 시스템 로그
```bash
# kubelet 로그
sudo journalctl -xfeu kubelet

# crio 로그
sudo journalctl -xfeu crio
```

## kubectl 명령어

### 자주 사용하는 명령
```bash
# 전체 Pod 상태
kubectl get pods -A

# 특정 네임스페이스
kubectl get pods -n cp-portal

# Pod 상세 정보
kubectl describe pod -n cp-portal <pod-name>

# Pod 재시작
kubectl rollout restart deployment -n cp-portal

# ConfigMap 확인
kubectl get cm -n cp-portal cp-portal-configmap -o yaml
```

### 디버깅
```bash
# Pod 내부 접속
kubectl exec -it -n cp-portal <pod-name> -- /bin/bash

# DNS 테스트
kubectl run -it --rm debug --image=busybox -- nslookup kubernetes

# 네트워크 테스트
kubectl run -it --rm debug --image=curlimages/curl -- curl -v http://service-name
```

## Vagrant 명령어

### VM 관리
```bash
# 상태 확인
vagrant status

# 전체 시작
vagrant up

# 특정 노드만
vagrant up master01

# 일시 중지
vagrant suspend

# 재개
vagrant resume

# 재시작
vagrant reload

# 프로비저닝만 재실행
vagrant provision master01

# 삭제
vagrant destroy -f
```

### 스냅샷
```bash
# 스냅샷 생성
vagrant snapshot save master01 after-k8s-install

# 스냅샷 목록
vagrant snapshot list

# 스냅샷 복원
vagrant snapshot restore master01 after-k8s-install
```

## Ansible

### 연결 테스트
```bash
source /vagrant/scripts/00.global_variable.sh

# SSH 키 복사
sshpass -pvagrant ssh-copy-id -i ~/.ssh/id_rsa.pub vagrant@"$MASTER01"
sshpass -pvagrant ssh-copy-id -i ~/.ssh/id_rsa.pub vagrant@"$MASTER02"
sshpass -pvagrant ssh-copy-id -i ~/.ssh/id_rsa.pub vagrant@"$WORKER01"
sshpass -pvagrant ssh-copy-id -i ~/.ssh/id_rsa.pub vagrant@"$WORKER02"

# Ping 테스트
ansible all -m ping -i ~/cp-deployment/standalone/inventory/mycluster/inventory.yml
```

## Helm

### 차트 관리
```bash
# 설치된 릴리즈 확인
helm list -A

# 릴리즈 상태
helm status keycloak -n keycloak

# 값 확인
helm get values keycloak -n keycloak

# 업그레이드
helm upgrade keycloak <chart> -f values.yaml -n keycloak

# 삭제
helm uninstall keycloak -n keycloak
```

## 플러그인 오류 해결

### VirtualBox Guest Additions
```bash
# 플러그인 설치
vagrant plugin install vagrant-vbguest

# 특정 버전 (호환성 문제 시)
vagrant plugin install vagrant-vbguest --plugin-version 0.32.0
```

### VMware
```bash
# VMware Utility 설치
brew install --cask vagrant-vmware-utility

# 디스크 플러그인
vagrant plugin install vagrant-disksize
```

## 유용한 alias

`~/.bashrc` 또는 `~/.zshrc`에 추가:
```bash
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgpa='kubectl get pods -A'
alias kgpw='kubectl get pods -o wide'
alias kd='kubectl describe'
alias kl='kubectl logs'
alias klf='kubectl logs -f'
alias vs='vagrant status'
alias vssh='vagrant ssh'
```
