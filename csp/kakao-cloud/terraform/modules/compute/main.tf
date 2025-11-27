# Compute Module - VM Instances
# This module manages Master and Worker VM instances for K-PaaS deployment

# Data sources for image and flavor lookup
data "kakaocloud_images" "images_all" {}

data "kakaocloud_instance_flavors" "flavors_all" {}

locals {
  ubuntu24_id = [
    for image in data.kakaocloud_images.images_all.images : image.id
    if image.name == var.image_name
  ][0]

  instance_flavor_id = [
    for flavor in data.kakaocloud_instance_flavors.flavors_all.instance_flavors : flavor.id
    if flavor.name == var.instance_flavor
  ][0]
}

# Master 노드 인스턴스 생성
resource "kakaocloud_instance" "master" {
  count       = var.master_count
  name        = "${var.master_name}-${count.index + 1}"
  description = "K-PaaS Master 노드 (Control Plane)"
  flavor_id   = local.instance_flavor_id
  image_id    = local.ubuntu24_id
  key_name    = var.key_name

  # 메인 서브넷에 연결
  subnets = [{ id = var.subnet_id }]

  # 보안 그룹 적용
  initial_security_groups = [{
    name = var.security_group_name
  }]

  # 부트 볼륨 크기 설정
  volumes = [{ size = var.volume_size }]

  # Cloud-init 사용자 데이터 설정
  user_data = var.cloud_init_base64
}

# Master 노드용 Public IP 생성 및 연결
resource "kakaocloud_public_ip" "master_ip" {
  count       = var.master_count
  description = "Public IP for ${var.master_name}-${count.index + 1}"

  related_resource = {
    id          = kakaocloud_instance.master[count.index].addresses[0].network_interface_id
    device_id   = kakaocloud_instance.master[count.index].id
    device_type = "instance"
  }
  depends_on = [kakaocloud_instance.master]
}

# Worker 노드 인스턴스 생성
resource "kakaocloud_instance" "worker" {
  count       = var.worker_count
  name        = "${var.worker_name}-${count.index + 1}"
  description = "K-PaaS Worker 노드 (Data Plane)"
  flavor_id   = local.instance_flavor_id
  image_id    = local.ubuntu24_id
  key_name    = var.key_name

  # 메인 서브넷에 연결
  subnets = [{ id = var.subnet_id }]

  # 보안 그룹 적용
  initial_security_groups = [{
    name = var.security_group_name
  }]

  # 부트 볼륨 크기 설정
  volumes = [{ size = var.volume_size }]

  # Cloud-init 사용자 데이터 설정
  user_data = var.cloud_init_base64
}

# Worker 노드용 Public IP 생성 및 연결
resource "kakaocloud_public_ip" "worker_ip" {
  count       = var.worker_count
  description = "Public IP for ${var.worker_name}-${count.index + 1}"

  related_resource = {
    id          = kakaocloud_instance.worker[count.index].addresses[0].network_interface_id
    device_id   = kakaocloud_instance.worker[count.index].id
    device_type = "instance"
  }
  depends_on = [kakaocloud_instance.worker]
}
