# K-PaaS Kakao Cloud Infrastructure
# Root configuration file that orchestrates all modules

# Local configuration
locals {
  generated_dir = "${path.module}/generated"
}

# Create generated directory
resource "null_resource" "create_generated_dir" {
  provisioner "local-exec" {
    command = "mkdir -p ${local.generated_dir}"
  }
}

#####################################################################
# Module 1: Network - VPC and Subnet
#####################################################################
module "network" {
  source = "./modules/network"

  vpc_name                = var.vpc_name
  vpc_cidr                = var.vpc_cidr
  vpc_default_subnet_cidr = var.vpc_default_subnet_cidr
  subnet_name             = var.subnet_name
  subnet_cidr             = var.subnet_cidr
  availability_zone       = var.availability_zone
}

#####################################################################
# Module 2: Security - Security Group
#####################################################################
module "security" {
  source = "./modules/security"

  security_group_name = var.security_group_name
  vpc_cidr            = module.network.vpc_cidr
  depends_on          = [module.network]
}

#####################################################################
# Module 3: Compute - Master and Worker Instances
#####################################################################
module "compute" {
  source = "./modules/compute"

  master_name         = var.master_name
  worker_name         = var.worker_name
  master_count        = var.master_count
  worker_count        = var.worker_count
  image_name          = var.image_name
  master_flavor       = var.master_flavor
  worker_flavor       = var.worker_flavor
  volume_size         = var.volume_size
  key_name            = var.key_name
  subnet_id           = module.network.subnet_id
  security_group_name = module.security.security_group_name
  cloud_init_base64   = filebase64("${path.module}/cloud-init.yaml")
  depends_on          = [module.security]
}

#####################################################################
# Module 4: LoadBalancer - Master and Worker Load Balancers
#####################################################################
module "loadbalancer" {
  source = "./modules/loadbalancer"

  master_lb_name               = var.master_lb_name
  worker_lb_name               = var.worker_lb_name
  availability_zone            = var.availability_zone
  subnet_id                    = module.network.subnet_id
  master_private_ips           = module.compute.master_private_ips
  worker_private_ips           = module.compute.worker_private_ips
  master_instances_dependency  = module.compute.master_instances
  master_public_ips_dependency = module.compute.master_public_ip_objects
  worker_instances_dependency  = module.compute.worker_instances
  worker_public_ips_dependency = module.compute.worker_public_ip_objects
  # depends_on removed to allow parallel creation with compute module

}

#####################################################################
# Module 5: Provisioner - K-PaaS Installation Automation
#####################################################################
module "provisioner" {
  source = "./modules/provisioner"

  master_count         = var.master_count
  worker_count         = var.worker_count
  master_private_ips   = module.compute.master_private_ips
  master_public_ips    = module.compute.master_public_ips
  worker_private_ips   = module.compute.worker_private_ips
  master_lb_vip        = module.loadbalancer.master_lb_vip
  master_lb_public_ip  = module.loadbalancer.master_lb_public_ip
  worker_lb_vip        = module.loadbalancer.worker_lb_vip
  worker_lb_public_ip  = module.loadbalancer.worker_lb_public_ip
  metallb_ip_range     = var.metallb_ip_range
  ingress_nginx_ip     = var.ingress_nginx_ip
  portal_domain        = var.portal_domain
  terraform_dir        = path.module
  generated_dir        = local.generated_dir
  ssh_key_path         = var.ssh_key_path
  auto_install_kpaas   = var.auto_install_kpaas
  master_lb_dependency = module.loadbalancer.master_lb

  depends_on = [module.compute, null_resource.create_generated_dir]
}
