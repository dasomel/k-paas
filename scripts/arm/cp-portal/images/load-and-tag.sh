#!/bin/bash

for f in cp-portal-*.tar.gz; do
  imagename=$(basename "$f" .tar.gz)
  tag="v1.6.2"
  fullimg="localhost/${imagename}:$tag"

  # 동일 이름으로 구동중인 컨테이너가 있으면 정지 및 삭제
  existing_cont=$(sudo podman ps -a --filter "ancestor=$fullimg" --format "{{.ID}}")
  if [[ -n "$existing_cont" ]]; then
    echo "Stopping/removing existing containers for $fullimg..."
    sudo podman stop $existing_cont
    sudo podman rm $existing_cont
  fi

  # 동일 이미지(태그) 존재시 삭제
  existing_img=$(sudo podman images --format "{{.Repository}}:{{.Tag}}" | grep -w "$fullimg")
  if [[ -n "$existing_img" ]]; then
    echo "Removing existing image $fullimg..."
    sudo podman rmi -f "$fullimg"
  fi

  # 이미지 로드 및 ID 추출
  output=$(sudo podman load -i "$f")
  tmp_name=$(echo "$output" | grep 'Loaded image' | head -1 | sed -E 's/Loaded image.*: //')

  if [[ "$tmp_name" == sha256:* ]]; then
    tmp_id="${tmp_name#sha256:}"
    sudo podman tag "$tmp_id" "$fullimg"
  else
    sudo podman tag "$tmp_name" "$fullimg"
  fi
  echo "Tagged $f as $fullimg"
done
