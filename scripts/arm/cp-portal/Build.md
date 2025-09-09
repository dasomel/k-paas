# Arm Support for CP-Portal

## 01. CP-Portal-UI 빌드를 위한 인증서 복사
```shell
vagrant ssh master01 -c "cp ~/workspace/container-platform/cp-portal-deployment/certs/k-paas.io.crt ./k-paas.io.crt"
```

## 02. container build & save
```shell
./container-build.sh
```

## 03. container image load & tagging
```shell
cd images
./load-and-tag.sh
```

## 04. image pull policy chang
```shell
cd images
./image_change.sh
```