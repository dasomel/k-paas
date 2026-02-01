# Layer 3: Cluster Infrastructure
# Compute instances with fixed IPs + Provisioner
# This layer can be destroyed and recreated without affecting Network/LB

terraform {
  required_providers {
    kakaocloud = {
      source  = "kakaoenterprise/kakaocloud"
      version = "0.2.0"
    }
  }
}

provider "kakaocloud" {
  application_credential_id     = var.application_credential_id
  application_credential_secret = var.application_credential_secret
}

#####################################################################
# Remote State - Network & LB Layer 참조
#####################################################################
data "terraform_remote_state" "network" {
  backend = "local"
  config = {
    path = "../01-network/terraform.tfstate"
  }
}

data "terraform_remote_state" "loadbalancer" {
  backend = "local"
  config = {
    path = "../02-loadbalancer/terraform.tfstate"
  }
}

locals {
  subnet_id           = data.terraform_remote_state.network.outputs.subnet_id
  availability_zone   = data.terraform_remote_state.network.outputs.availability_zone
  key_name            = data.terraform_remote_state.network.outputs.key_name
  ssh_key_path        = data.terraform_remote_state.network.outputs.ssh_key_path
  security_group_name = data.terraform_remote_state.loadbalancer.outputs.security_group_name
  master_lb_vip       = data.terraform_remote_state.loadbalancer.outputs.master_lb_vip
  master_lb_public_ip = data.terraform_remote_state.loadbalancer.outputs.master_lb_public_ip
  worker_lb_vip       = data.terraform_remote_state.loadbalancer.outputs.worker_lb_vip
  worker_lb_public_ip = data.terraform_remote_state.loadbalancer.outputs.worker_lb_public_ip
  master_private_ips  = data.terraform_remote_state.loadbalancer.outputs.master_private_ips
  worker_private_ips  = data.terraform_remote_state.loadbalancer.outputs.worker_private_ips
  generated_dir       = "${path.module}/generated"
}

#####################################################################
# Data Sources
#####################################################################
data "kakaocloud_images" "ubuntu" {
  filter = [
    {
      name  = "name"
      value = var.image_name
    }
  ]
}

data "kakaocloud_instance_flavors" "master" {
  filter = [
    {
      name  = "name"
      value = var.master_flavor
    }
  ]
}

data "kakaocloud_instance_flavors" "worker" {
  filter = [
    {
      name  = "name"
      value = var.worker_flavor
    }
  ]
}

#####################################################################
# Generated Scripts Directory
#####################################################################
resource "null_resource" "create_generated_dir" {
  provisioner "local-exec" {
    command = "mkdir -p ${local.generated_dir}"
  }
}

#####################################################################
# Master Instances (Fixed IPs)
#####################################################################
resource "kakaocloud_instance" "master" {
  count       = var.master_count
  name        = "${var.master_name}-${count.index + 1}"
  description = "K-PaaS Master Node ${count.index + 1}"
  flavor_id   = data.kakaocloud_instance_flavors.master.instance_flavors[0].id
  image_id    = data.kakaocloud_images.ubuntu.images[0].id
  key_name    = local.key_name

  subnets = [
    {
      id         = local.subnet_id
      private_ip = local.master_private_ips[count.index]  # Fixed IP!
    }
  ]

  initial_security_groups = [
    {
      name = local.security_group_name
    }
  ]

  volumes = [
    {
      size = var.volume_size
    }
  ]

  user_data = filebase64("${path.module}/../../terraform/cloud-init.yaml")

  lifecycle {
    ignore_changes = [initial_security_groups, volumes, user_data, subnets]
  }
}

# Master Public IPs
resource "kakaocloud_public_ip" "master" {
  count       = var.master_count
  description = "Public IP for ${var.master_name}-${count.index + 1}"

  related_resource = {
    id          = kakaocloud_instance.master[count.index].addresses[0].network_interface_id
    device_id   = kakaocloud_instance.master[count.index].id
    device_type = "instance"
  }

  depends_on = [kakaocloud_instance.master]
}

#####################################################################
# Worker Instances (Fixed IPs)
#####################################################################
resource "kakaocloud_instance" "worker" {
  count       = var.worker_count
  name        = "${var.worker_name}-${count.index + 1}"
  description = "K-PaaS Worker Node ${count.index + 1}"
  flavor_id   = data.kakaocloud_instance_flavors.worker.instance_flavors[0].id
  image_id    = data.kakaocloud_images.ubuntu.images[0].id
  key_name    = local.key_name

  subnets = [
    {
      id         = local.subnet_id
      private_ip = local.worker_private_ips[count.index]  # Fixed IP!
    }
  ]

  initial_security_groups = [
    {
      name = local.security_group_name
    }
  ]

  volumes = [
    {
      size = var.volume_size
    }
  ]

  user_data = filebase64("${path.module}/../../terraform/cloud-init.yaml")

  lifecycle {
    ignore_changes = [initial_security_groups, volumes, user_data, subnets]
  }
}

# Worker Public IPs
resource "kakaocloud_public_ip" "worker" {
  count       = var.worker_count
  description = "Public IP for ${var.worker_name}-${count.index + 1}"

  related_resource = {
    id          = kakaocloud_instance.worker[count.index].addresses[0].network_interface_id
    device_id   = kakaocloud_instance.worker[count.index].id
    device_type = "instance"
  }

  depends_on = [kakaocloud_instance.worker]
}

#####################################################################
# Provisioner Scripts Generation
#####################################################################
resource "local_file" "global_variable" {
  content = templatefile("${path.module}/../../terraform/modules/provisioner/templates/00.global_variable.sh.tpl", {
    master_lb_vip       = local.master_lb_vip
    master_lb_public_ip = local.master_lb_public_ip
    worker_lb_vip       = local.worker_lb_vip
    worker_lb_public_ip = local.worker_lb_public_ip
    master1_private_ip  = local.master_private_ips[0]
    master2_private_ip  = local.master_private_ips[1]
    master3_private_ip  = local.master_private_ips[2]
    master1_public_ip   = kakaocloud_public_ip.master[0].public_ip
    master2_public_ip   = kakaocloud_public_ip.master[1].public_ip
    master3_public_ip   = kakaocloud_public_ip.master[2].public_ip
    worker1_private_ip  = local.worker_private_ips[0]
    worker2_private_ip  = local.worker_private_ips[1]
    worker3_private_ip  = local.worker_private_ips[2]
    ingress_nginx_ip    = var.ingress_nginx_ip
    portal_domain       = var.portal_domain
  })
  filename        = "${local.generated_dir}/00.global_variable.sh"
  file_permission = "0755"

  depends_on = [null_resource.create_generated_dir]
}

resource "local_file" "install_kpaas" {
  content = templatefile("${path.module}/../../terraform/modules/provisioner/templates/05.master_install_k-pass.sh.tpl", {
    master01_hostname = "master01"
    master01_ip       = local.master_private_ips[0]
    master02_hostname = "master02"
    master02_ip       = local.master_private_ips[1]
    master03_hostname = "master03"
    master03_ip       = local.master_private_ips[2]
    worker01_hostname = "worker01"
    worker01_ip       = local.worker_private_ips[0]
    worker02_hostname = "worker02"
    worker02_ip       = local.worker_private_ips[1]
    worker03_hostname = "worker03"
    worker03_ip       = local.worker_private_ips[2]
    cluster_endpoint  = local.master_lb_vip
    metallb_ip_range  = var.metallb_ip_range
    ingress_nginx_ip  = var.ingress_nginx_ip
  })
  filename        = "${local.generated_dir}/05.master_install_k-pass.sh"
  file_permission = "0755"

  depends_on = [null_resource.create_generated_dir]
}

resource "local_file" "install_portal" {
  content = templatefile("${path.module}/../../terraform/modules/provisioner/templates/06.master_install_k-pass_portal.sh.tpl", {
    PORTAL_MASTER_NODE_PUBLIC_IP = local.master_lb_public_ip
    PORTAL_HOST_DOMAIN           = var.portal_domain
    PORTAL_HOST_IP               = local.worker_lb_public_ip
    CLUSTER_ENDPOINT             = local.master_lb_vip
  })
  filename        = "${local.generated_dir}/06.master_install_k-pass_portal.sh"
  file_permission = "0755"

  depends_on = [null_resource.create_generated_dir]
}

resource "local_file" "common_setting" {
  content         = templatefile("${path.module}/../../terraform/modules/provisioner/templates/01.all_common_setting.sh.tpl", {})
  filename        = "${local.generated_dir}/01.all_common_setting.sh"
  file_permission = "0755"

  depends_on = [null_resource.create_generated_dir]
}

resource "local_file" "nfs_server" {
  content = templatefile("${path.module}/../../terraform/modules/provisioner/templates/03.master_nfs_server.sh.tpl", {
    master1_private_ip = local.master_private_ips[0]
    master2_private_ip = local.master_private_ips[1]
    master3_private_ip = local.master_private_ips[2]
    worker1_private_ip = local.worker_private_ips[0]
    worker2_private_ip = local.worker_private_ips[1]
    worker3_private_ip = local.worker_private_ips[2]
  })
  filename        = "${local.generated_dir}/03.master_nfs_server.sh"
  file_permission = "0755"

  depends_on = [null_resource.create_generated_dir]
}

resource "local_file" "ssh_setting" {
  content = templatefile("${path.module}/../../terraform/modules/provisioner/templates/04.master_ssh_setting.sh.tpl", {
    master1_private_ip = local.master_private_ips[0]
    master2_private_ip = local.master_private_ips[1]
    master3_private_ip = local.master_private_ips[2]
    worker1_private_ip = local.worker_private_ips[0]
    worker2_private_ip = local.worker_private_ips[1]
    worker3_private_ip = local.worker_private_ips[2]
  })
  filename        = "${local.generated_dir}/04.master_ssh_setting.sh"
  file_permission = "0755"

  depends_on = [null_resource.create_generated_dir]
}

#####################################################################
# Provisioner - SSH to Master-1 and run scripts
#####################################################################
resource "null_resource" "provision_master1" {
  count = var.auto_install_kpaas ? 1 : 0

  depends_on = [
    kakaocloud_instance.master,
    kakaocloud_instance.worker,
    kakaocloud_public_ip.master,
    kakaocloud_public_ip.worker,
    local_file.global_variable,
    local_file.common_setting,
    local_file.nfs_server,
    local_file.ssh_setting,
    local_file.install_kpaas,
    local_file.install_portal
  ]

  triggers = {
    master1_ip = kakaocloud_public_ip.master[0].public_ip
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(pathexpand(local.ssh_key_path))
    host        = kakaocloud_public_ip.master[0].public_ip
    timeout     = "5m"
  }

  # Create scripts directory
  provisioner "remote-exec" {
    inline = [
      "mkdir -p /home/ubuntu/scripts",
      "mkdir -p /home/ubuntu/scripts/variable"
    ]
  }

  # Upload SSH key
  provisioner "file" {
    source      = pathexpand(local.ssh_key_path)
    destination = "/home/ubuntu/.ssh/kaas_keypriar.pem"
  }

  # Upload scripts
  provisioner "file" {
    source      = "${local.generated_dir}/00.global_variable.sh"
    destination = "/home/ubuntu/scripts/00.global_variable.sh"
  }

  provisioner "file" {
    source      = "${local.generated_dir}/01.all_common_setting.sh"
    destination = "/home/ubuntu/scripts/01.all_common_setting.sh"
  }

  provisioner "file" {
    source      = "${local.generated_dir}/03.master_nfs_server.sh"
    destination = "/home/ubuntu/scripts/03.master_nfs_server.sh"
  }

  provisioner "file" {
    source      = "${local.generated_dir}/04.master_ssh_setting.sh"
    destination = "/home/ubuntu/scripts/04.master_ssh_setting.sh"
  }

  provisioner "file" {
    source      = "${local.generated_dir}/05.master_install_k-pass.sh"
    destination = "/home/ubuntu/scripts/05.master_install_k-pass.sh"
  }

  provisioner "file" {
    source      = "${local.generated_dir}/06.master_install_k-pass_portal.sh"
    destination = "/home/ubuntu/scripts/06.master_install_k-pass_portal.sh"
  }

  provisioner "file" {
    source      = "${path.module}/../../terraform/modules/provisioner/scripts/install_kpaas.sh"
    destination = "/home/ubuntu/scripts/install_kpaas.sh"
  }

  # Set permissions and run
  provisioner "remote-exec" {
    inline = [
      "chmod 600 /home/ubuntu/.ssh/kaas_keypriar.pem",
      "chmod +x /home/ubuntu/scripts/*.sh",
      "echo '=========================================='",
      "echo 'Starting K-PaaS Installation'",
      "echo '=========================================='",
      "nohup bash /home/ubuntu/scripts/install_kpaas.sh > /home/ubuntu/kpaas_install.log 2>&1 &",
      "echo 'Installation started in background'",
      "echo 'Check progress: tail -f /home/ubuntu/kpaas_install.log'",
      "sleep 5"
    ]
  }
}

#####################################################################
# Outputs
#####################################################################
output "master_public_ips" {
  description = "Master node public IPs"
  value       = kakaocloud_public_ip.master[*].public_ip
}

output "master_private_ips" {
  description = "Master node private IPs (fixed)"
  value       = local.master_private_ips
}

output "worker_public_ips" {
  description = "Worker node public IPs"
  value       = kakaocloud_public_ip.worker[*].public_ip
}

output "worker_private_ips" {
  description = "Worker node private IPs (fixed)"
  value       = local.worker_private_ips
}

output "ssh_command" {
  description = "SSH command to connect to Master-1"
  value       = "ssh -i ${local.ssh_key_path} ubuntu@${kakaocloud_public_ip.master[0].public_ip}"
}

output "install_log_command" {
  description = "Command to check installation progress"
  value       = "ssh -i ${local.ssh_key_path} ubuntu@${kakaocloud_public_ip.master[0].public_ip} 'tail -f /home/ubuntu/kpaas_install.log'"
}
