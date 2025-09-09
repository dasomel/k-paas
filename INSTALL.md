# Kubernetes 설치

## VirtualBox 특화 문제 / Apple Silicon 환경
```shell
# VirtualBox 네트워크 드라이버 재시작
sudo /Library/Application\ Support/VirtualBox/LaunchDaemons/VirtualBoxStartup.sh restart

# Host-Only Network 수동 생성
VBoxManage hostonlyif create
VBoxManage list hostonlyifs
```

---

## Arm 환경을 위한 사전 준비

### 00. CP-Portal-UI 빌드를 위한 인증서 복사
```shell
vagrant ssh master01 -c "cp ~/workspace/container-platform/cp-portal-deployment/certs/k-paas.io.crt ./k-paas.io.crt"
```

### 01. harbor ARM용 Helm chart 작성
- harbor Helm chart pull 및 에러 수정
```shell
# Error: container create failed: creating `/etc/core/token`: openat2 `etc/core/token`: No such file or directory
./script/arm/helm/harbor.sh
```

### 02. CP-Portal Continer image 생성
- arm용 container image build 및 save
```shell
# image build & save
./script/arm/cp-portal/container-build.sh

# image load & tagging
./script/arm/cp-portal/images/load-and-tag.sh

# 기본 배포된 이미지 tag 수정
./script/arm/cp-portal/images/image_change.sh
```

---

## VM 생성
```shell
vagrant up &> ./logs/vagrant_$(date +%Y%m%d_%H%M%S).log

# 최신 파일 로그 조회
tail -f $(ls -Art  | tail -n 1)

# master01: TASK [cp-install : Run container platform deployment] **************************
vagrant ssh master01 -c "tail -f ~/cp-deployment/single/deploy-result.log"

# Log: Portal
vagrant ssh master01 -c "tail -f ~/workspace/container-platform/cp-portal-deployment/script/deploy-portal-result.log"

# 컨테이너 플랫폼 포털 배포 스크립트 실행
cd "$INSTALL_PATH"/workspace/container-platform/cp-portal-deployment/script || exit
chmod +x deploy-cp-portal.sh
./deploy-cp-portal.sh > deploy-portal-result.log
```

## VM 삭제
```shell
vagrant destroy -f
```

## VM 상태
```shell
vagrant status
```

## VM 접속
```shell
vagrant ssh master01 # 마스터 노드 접속 예시
vagrant ssh worker01 # 워커 노드 접속 예시
```

## VM IP 확인
```shell
vagrant ssh master1 -c "hostname -I | awk '{print $1}'"
```

---

### Trouble Shutting
- Vagrant can't use the requested machine because it is locked! This
  means that another Vagrant process is currently reading or modifying
  the machine. Please wait for that Vagrant process to end and try
  again. Details about the machine are shown below:

```shell
# Vagrant 관련 프로세스 종료
pkill -f vagrant
pkill -f ruby

# Vagrant 인덱스 재설정
rm -f ~/.vagrant.d/data/machine-index/index
rm -f ~/.vagrant.d/data/machine-index/index.lock

# 박스 제거 후 재설치
vagrant box remove generic/ubuntu2204
rm -rf ~/.vagrant.d/boxes
 
# RubyGems 캐시 정리
gem cleanup

# 최후 수단 모두 삭제
rm -Rf ~/.vagrant.d/
```

---

- vagrant-vbguest 플러그인(0.32.0 버전) 코드에 File.exists?가 사용
~~~
/Users/m/.vagrant.d/gems/3.3.8/gems/vagrant-vbguest-0.32.0/lib/vagrant-vbguest/hosts/virtualbox.rb:84:in `block in guess_local_iso': undefined method `exists?' for class File (NoMethodError)

            path && File.exists?(path)
                        ^^^^^^^^
Did you mean?  exist?
~~~
```shell
vagrant plugin update vagrant-vbguest

brew upgrade vagrant
brew upgrade --cask virtualbox
```
~~~
sudo vi /Users/m/.vagrant.d/gems/3.3.8/gems/vagrant-vbguest-0.32.0/lib/vagrant-vbguest/hosts/virtualbox.rb
File.exists? -> File.exist? 로 84번째 줄 수정
~~~

---

# (combined from similar events): Failed to create pod sandbox: rpc error: code = Unknown desc = failed to create pod network sandbox k8s_harbor-core-7ff8f757b8-4kq65_harbor_d56269b6-2187-4f45-b66a-e2c49cd3e6ba_0(bda453a54235af1b64e1ee97bc533624b7c4b0a1bf04a18598b65089299aeae2): error adding pod harbor_harbor-core-7ff8f757b8-4kq65 to CNI network "k8s-pod-network": plugin type="calico" failed (add): error getting ClusterInformation: connection is unauthorized: Unauthorize
```shell
vagrant ssh master01 -c "sudo systemctl restart kubelet"
vagrant ssh master02 -c "sudo systemctl restart kubelet"
vagrant ssh worker01 -c "sudo systemctl restart kubelet"
vagrant ssh worker02 -c "sudo systemctl restart kubelet"

```
