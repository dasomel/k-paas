# Provisioner Module - K-PaaS Installation Automation
# This module generates installation scripts from templates and provisions them to Master-1

# 템플릿 렌더링을 위한 로컬 변수 정의
locals {
  master_count = var.master_count
  worker_count = var.worker_count

  # Master 노드 IP 목록
  master1_private_ip = length(var.master_private_ips) > 0 ? var.master_private_ips[0] : ""
  master2_private_ip = length(var.master_private_ips) > 1 ? var.master_private_ips[1] : ""
  master3_private_ip = length(var.master_private_ips) > 2 ? var.master_private_ips[2] : ""

  master1_public_ip = length(var.master_public_ips) > 0 ? var.master_public_ips[0] : ""
  master2_public_ip = length(var.master_public_ips) > 1 ? var.master_public_ips[1] : ""
  master3_public_ip = length(var.master_public_ips) > 2 ? var.master_public_ips[2] : ""

  # Worker 노드 IP 목록
  worker1_private_ip = length(var.worker_private_ips) > 0 ? var.worker_private_ips[0] : ""
  worker2_private_ip = length(var.worker_private_ips) > 1 ? var.worker_private_ips[1] : ""
  worker3_private_ip = length(var.worker_private_ips) > 2 ? var.worker_private_ips[2] : ""
}

# 템플릿에서 cp-cluster-vars.sh 생성
resource "local_file" "cp_cluster_vars" {
  content = templatefile("${path.module}/templates/cp-cluster-vars.sh.tpl", {
    master_count        = local.master_count
    worker_count        = local.worker_count
    master_lb_vip       = var.master_lb_vip
    master_lb_public_ip = var.master_lb_public_ip
    master1_public_ip   = local.master1_public_ip
    master1_private_ip  = local.master1_private_ip
    master2_private_ip  = local.master2_private_ip
    master3_private_ip  = local.master3_private_ip
    worker1_private_ip  = local.worker1_private_ip
    worker2_private_ip  = local.worker2_private_ip
    worker3_private_ip  = local.worker3_private_ip
    metallb_ip_range    = var.metallb_ip_range
    ingress_nginx_ip    = var.ingress_nginx_ip
    terraform_dir       = var.terraform_dir
  })
  filename        = "${var.generated_dir}/cp-cluster-vars.sh"
  file_permission = "0755"
}

# 템플릿에서 00.global_variable.sh 생성
resource "local_file" "global_variable" {
  content = templatefile("${path.module}/templates/00.global_variable.sh.tpl", {
    master_lb_vip       = var.master_lb_vip
    master_lb_public_ip = var.master_lb_public_ip
    worker_lb_vip       = var.worker_lb_vip
    worker_lb_public_ip = var.worker_lb_public_ip
    master1_private_ip  = local.master1_private_ip
    master2_private_ip  = local.master2_private_ip
    master3_private_ip  = local.master3_private_ip
    master1_public_ip   = local.master1_public_ip
    master2_public_ip   = local.master2_public_ip
    master3_public_ip   = local.master3_public_ip
    worker1_private_ip  = local.worker1_private_ip
    worker2_private_ip  = local.worker2_private_ip
    worker3_private_ip  = local.worker3_private_ip
    ingress_nginx_ip    = var.ingress_nginx_ip
    portal_domain       = var.portal_domain
  })
  filename        = "${var.generated_dir}/00.global_variable.sh"
  file_permission = "0755"
}

# 템플릿에서 03.master_nfs_server.sh 생성
resource "local_file" "master_nfs_server" {
  content = templatefile("${path.module}/templates/03.master_nfs_server.sh.tpl", {
    master1_private_ip = local.master1_private_ip
    master2_private_ip = local.master2_private_ip
    master3_private_ip = local.master3_private_ip
    worker1_private_ip = local.worker1_private_ip
    worker2_private_ip = local.worker2_private_ip
    worker3_private_ip = local.worker3_private_ip
  })
  filename        = "${var.generated_dir}/03.master_nfs_server.sh"
  file_permission = "0755"
}

# 템플릿에서 04.master_ssh_setting.sh 생성
resource "local_file" "master_ssh_setting" {
  content = templatefile("${path.module}/templates/04.master_ssh_setting.sh.tpl", {
    master1_private_ip = local.master1_private_ip
    master2_private_ip = local.master2_private_ip
    master3_private_ip = local.master3_private_ip
    worker1_private_ip = local.worker1_private_ip
    worker2_private_ip = local.worker2_private_ip
    worker3_private_ip = local.worker3_private_ip
  })
  filename        = "${var.generated_dir}/04.master_ssh_setting.sh"
  file_permission = "0755"
}

# 템플릿에서 01.all_common_setting.sh 생성
resource "local_file" "all_common_setting" {
  content         = templatefile("${path.module}/templates/01.all_common_setting.sh.tpl", {})
  filename        = "${var.generated_dir}/01.all_common_setting.sh"
  file_permission = "0755"
}

# 템플릿에서 05.master_install_k-pass.sh 생성
resource "local_file" "master_install_kpaas" {
  content = templatefile("${path.module}/templates/05.master_install_k-pass.sh.tpl", {
    master01_hostname = "master01"
    master01_ip       = local.master1_private_ip
    master02_hostname = "master02"
    master02_ip       = local.master2_private_ip
    master03_hostname = "master03"
    master03_ip       = local.master3_private_ip
    worker01_hostname = "worker01"
    worker01_ip       = local.worker1_private_ip
    worker02_hostname = "worker02"
    worker02_ip       = local.worker2_private_ip
    worker03_hostname = "worker03"
    worker03_ip       = local.worker3_private_ip
    cluster_endpoint  = var.master_lb_vip
    metallb_ip_range  = var.metallb_ip_range
    ingress_nginx_ip  = var.ingress_nginx_ip
  })
  filename        = "${var.generated_dir}/05.master_install_k-pass.sh"
  file_permission = "0755"
}

# 템플릿에서 06.master_install_k-pass_portal.sh 생성
resource "local_file" "master_install_portal" {
  content = templatefile("${path.module}/templates/06.master_install_k-pass_portal.sh.tpl", {
    PORTAL_MASTER_NODE_PUBLIC_IP = var.master_lb_public_ip
    PORTAL_HOST_DOMAIN           = var.portal_domain
    PORTAL_HOST_IP               = var.worker_lb_public_ip
    CLUSTER_ENDPOINT             = var.master_lb_vip
  })
  filename        = "${var.generated_dir}/06.master_install_k-pass_portal.sh"
  file_permission = "0755"
}

# Master-1 노드에 스크립트 전송 및 실행을 위한 Null Resource
resource "null_resource" "provision_master1" {
  count = var.auto_install_kpaas ? 1 : 0

  depends_on = [
    var.master_lb_dependency,
    local_file.cp_cluster_vars,
    local_file.global_variable,
    local_file.master_nfs_server,
    local_file.master_ssh_setting,
    local_file.all_common_setting
  ]

  # 스크립트 내용 변경 시 재실행 트리거
  triggers = {
    cluster_vars_sha = local_file.cp_cluster_vars.content
    global_var_sha   = local_file.global_variable.content
    nfs_server_sha   = local_file.master_nfs_server.content
    ssh_setting_sha  = local_file.master_ssh_setting.content
    master1_ip       = local.master1_public_ip
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(pathexpand(var.ssh_key_path))
    host        = local.master1_public_ip
    timeout     = "5m"
  }

  # 스크립트 디렉토리 생성
  provisioner "remote-exec" {
    inline = [
      "mkdir -p /home/ubuntu/scripts",
      "mkdir -p /home/ubuntu/scripts/variable"
    ]
  }

  # 접속 pem 키 파일 복사
  provisioner "file" {
    source      = pathexpand(var.ssh_key_path)
    destination = "/home/ubuntu/.ssh/kaas_keypriar.pem"
  }

  # 키 파일 권한 설정
  provisioner "remote-exec" {
    inline = [
      "chmod 600 /home/ubuntu/.ssh/kaas_keypriar.pem"
    ]
  }

  # 생성된 스크립트 업로드
  provisioner "file" {
    source      = "${var.generated_dir}/00.global_variable.sh"
    destination = "/home/ubuntu/scripts/00.global_variable.sh"
  }

  provisioner "file" {
    source      = "${var.generated_dir}/cp-cluster-vars.sh"
    destination = "/home/ubuntu/scripts/variable/cp-cluster-vars.sh"
  }

  provisioner "file" {
    source      = "${var.generated_dir}/03.master_nfs_server.sh"
    destination = "/home/ubuntu/scripts/03.master_nfs_server.sh"
  }

  provisioner "file" {
    source      = "${var.generated_dir}/04.master_ssh_setting.sh"
    destination = "/home/ubuntu/scripts/04.master_ssh_setting.sh"
  }

  provisioner "file" {
    source      = "${var.generated_dir}/01.all_common_setting.sh"
    destination = "/home/ubuntu/scripts/01.all_common_setting.sh"
  }

  provisioner "file" {
    source      = "${var.generated_dir}/05.master_install_k-pass.sh"
    destination = "/home/ubuntu/scripts/05.master_install_k-pass.sh"
  }

  provisioner "file" {
    source      = "${var.generated_dir}/06.master_install_k-pass_portal.sh"
    destination = "/home/ubuntu/scripts/06.master_install_k-pass_portal.sh"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/install_kpaas.sh"
    destination = "/home/ubuntu/scripts/install_kpaas.sh"
  }

  # 실행 권한 부여
  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ubuntu/scripts/*.sh",
      "chmod +x /home/ubuntu/scripts/variable/*.sh"
    ]
  }

  # K-PaaS 설치 실행
  provisioner "remote-exec" {
    inline = [
      "echo '=========================================='",
      "echo 'Starting K-PaaS Automated Installation'",
      "echo '=========================================='",
      "nohup bash /home/ubuntu/scripts/install_kpaas.sh > /home/ubuntu/kpaas_install.log 2>&1 &",
      "echo 'K-PaaS installation started in background'",
      "echo 'Check installation progress: tail -f /home/ubuntu/kpaas_install.log'",
      "echo 'Installation will take approximately 20-40 minutes'",
      "sleep 5"
    ]
  }
}
