#!/usr/bin/env bash

version="master"
tag=v1.6.2

repository_gradle_list=(
  "cp-portal-api"
  "cp-portal-ui"
  "cp-portal-common-api"
)
for repo in "${repository_gradle_list[@]}"; do
  echo "Building $repo..."
  git clone -b $version --single-branch https://github.com/K-PaaS/"$repo".git
  cd "$repo" || exit
  # Jacoco destination 구문 자동 주석 처리
  sed -i.bak '/destination(/ s/^/\/\/ /' build.gradle
  sed -i.bak '/archivesBaseName/ s/^/\/\/ /' build.gradle
  sed -i.bak '/xml\.destination file/s/^/\/\/ /' build.gradle
  sed -i.bak '/html\.destination file/s/^/\/\/ /' build.gradle
  sed -i.bak 's/openjdk:8-jdk-alpine/eclipse-temurin:17-jdk-jammy/g' ./Dockerfile
  sed -i.bak 's|^[[:space:]]*RUN[[:space:]]*addgroup[[:space:]]*-S[[:space:]]*1000[[:space:]]*&&[[:space:]]*adduser[[:space:]]*-S[[:space:]]*1000[[:space:]]*-G[[:space:]]*1000[[:space:]]*$|RUN groupadd -g 1000 appgroup \&\& useradd -u 1000 -g 1000 appuser|' Dockerfile
  gradle clean build -x test --no-daemon --parallel
  if [[ "$repo" == "cp-portal-common-api" ]]; then
    sed -i '' 's/alpine/slim/g' ./Dockerfile
    sed -i '/^COPY /a RUN mkdir -p /home/1000/logs \&\& chown 1000 /home/1000/logs' ./Dockerfile
    sed -i '' 's|RUN apk update && apk upgrade && apk add --no-cache bash|RUN apt-get update \&\& apt-get upgrade -y \&\& apt-get install -y bash|g' ./Dockerfile
  fi
  if [[ "$repo" == "cp-portal-ui" ]]; then
    #vagrant ssh master01 -c "cp ~/workspace/container-platform/cp-portal-deployment/certs/k-paas.io.crt ./k-paas.io.crt"
    cp ../k-paas.io.crt .
    sed -i '' '/^ENTRYPOINT /i\
COPY k-paas.io.crt /tmp/k-paas.io.crt\
RUN keytool -import -trustcacerts -keystore \$JAVA_HOME/lib/security/cacerts -storepass changeit -noprompt -alias keycloak -file /tmp/k-paas.io.crt
' Dockerfile
  fi
  docker build -t $repo:$tag .
  cd ..
  mkdir -p ./images
  docker save $repo:$tag | gzip > ./images/"$repo".tar.gz
  echo "$repo built and saved as images/${repo}.tar.gz"
done

repository_modify_gradle_list=(
  "cp-chaos-api"
  "cp-chaos-collector"
  "cp-terraman"
)
for repo in "${repository_modify_gradle_list[@]}"; do
  echo "Building $repo..."
  git clone -b $version --single-branch https://github.com/K-PaaS/"$repo".git
  cd "$repo" || exit
  # Jacoco destination 구문 자동 주석 처리
  sed -i.bak '/destination(/ s/^/\/\/ /' build.gradle
  sed -i.bak '/archivesBaseName/ s/^/\/\/ /' build.gradle
  sed -i.bak '/xml\.destination file/s/^/\/\/ /' build.gradle
  sed -i.bak '/html\.destination file/s/^/\/\/ /' build.gradle
  sed -i.bak 's/openjdk:8-jdk-alpine/eclipse-temurin:17-jdk-jammy/g' ./Dockerfile
  sed -i.bak 's|^[[:space:]]*RUN[[:space:]]*addgroup[[:space:]]*-S[[:space:]]*1000[[:space:]]*&&[[:space:]]*adduser[[:space:]]*-S[[:space:]]*1000[[:space:]]*-G[[:space:]]*1000[[:space:]]*$|RUN groupadd -g 1000 appgroup \&\& useradd -u 1000 -g 1000 appuser|' ./Dockerfile
  gradle clean build -x test --no-daemon --parallel
  if [[ "$repo" == "cp-terraman" ]]; then
    sed -i '' 's/alpine/slim/g' ./Dockerfile
    sed -i '' '/RUN apk add --no-cache/,/bash/ {
      s|RUN apk add --no-cache|RUN apt-get update \&\& apt-get install -y|
      /bash/ s|$| \&\& rm -rf /var/lib/apt/lists/*|
    }' ./Dockerfile
    sed -i '' '/^RUN addgroup/c\
RUN groupadd -r -g 1000 appgroup && useradd -r -u 1000 -g appgroup appuser
    ' Dockerfile
    sed -i '' 's/amd/arm/g' ./Dockerfile
    sed -i '' 's|RUN apk update && apk upgrade && apk add --no-cache bash|RUN apt-get update \&\& apt-get upgrade -y \&\& apt-get install -y bash|g' ./Dockerfile
  fi
  new_repo="${repo/cp-/cp-portal-}"
  docker build -t $new_repo:$tag .
  cd ..
  docker save $new_repo:$tag | gzip > ./images/"$new_repo".tar.gz
  echo "$new_repo built and saved as images/${new_repo}.tar.gz"
done

repository_go_list=(
  "cp-catalog-api"
  "cp-metrics-api"
)

for repo in "${repository_go_list[@]}"; do
  echo "Building $repo..."
  git clone -b $version --single-branch https://github.com/K-PaaS/"$repo".git
  cd "$repo" || exit
  new_repo="${repo/cp-/cp-portal-}"
  if [[ "$new_repo" == *metrics* ]]; then
    new_repo="${new_repo/metrics/metric}"
  else
    sed -i '' 's/app/config/g' ./Dockerfile
  fi
  sed -i '' 's/amd64/arm64/g' ./Dockerfile
  docker build -t $new_repo:$tag .
  cd ..
  docker save $new_repo:$tag | gzip > ./images/"$new_repo".tar.gz
  echo "$new_repo built and saved as images/${new_repo}.tar.gz"
done

kubectl -n cp-portal cp cp-portal-ui-deployment-5d56f75fb-b985n:home/1000/container-platform-ui.war ./container-platform-ui.war
kubectl -n cp-portal cp ./myfile.txt cp-portal-ui-abc123:/tmp/myfile.txt
