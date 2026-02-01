# 1. 새로운 빌더 생성 및 사용 설정
docker buildx create --name mybuilder --use

# 2. 빌더 초기화 및 상태 확인
docker buildx inspect --bootstrap

docker login registry.k-paas.org --username dasomell --password Wa1NZwcL9Lr9BqNgOnezdrJdmPWSESMa

docker push registry.k-paas.org/egovframework/web-sample:4.3.0



docker buildx build \
--platform linux/amd64,linux/arm64 \
-t <레지스트리주소>/<이미지이름>:<태그> \
--push \
.



docker buildx build . \
--platform linux/amd64,linux/arm64 \
-t registry.k-paas.org/egovframework/web-sample:4.3.0
.

이미지 서명
brew install cosign

# 2단계: 키 쌍 생성
cosign generate-key-pair
# egov


# 3단계: 컨테이너 이미지 서명

# (cosign sign --key cosign.key <이미지 주소>)
cosign sign --key cosign.key registry.k-paas.org/egovframework/web-sample:4.3.0

# 4단계: 서명 검증
# cosign verify --key cosign.pub <이미지 주소>

cosign verify --key cosign.pub registry.k-paas.org/egovframework/web-sample:4.3.0

trivy image --format spdx-json -o web-sample.sbom.spdx.json  registry.k-paas.org/egovframework/web-sample:4.3.0