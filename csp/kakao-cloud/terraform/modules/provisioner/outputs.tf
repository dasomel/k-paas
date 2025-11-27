# Provisioner Module Outputs

output "provisioner_status" {
  description = "K-PaaS provisioner status"
  value = {
    master1_provisioned = length(null_resource.provision_master1) > 0 ? "completed" : "disabled"
    scripts_location    = "/home/ubuntu/scripts"
    master1_public_ip   = length(var.master_public_ips) > 0 ? var.master_public_ips[0] : ""
    auto_install        = var.auto_install_kpaas
    kpaas_installation  = var.auto_install_kpaas ? "K-PaaS installation is running in background on Master-1" : "K-PaaS auto-installation is disabled"
    installation_log    = var.auto_install_kpaas ? "/home/ubuntu/kpaas_install.log" : "N/A"
    check_installation = var.auto_install_kpaas ? [
      "1. SSH to master-1: ssh -i ${var.ssh_key_path} ubuntu@${length(var.master_public_ips) > 0 ? var.master_public_ips[0] : ""}",
      "2. Check installation progress: tail -f /home/ubuntu/kpaas_install.log",
      "3. Check cluster status: kubectl get nodes",
      "4. Check all pods: kubectl get pods -A",
      "5. Test API Server (Internal): curl -k https://${var.master_lb_vip}:6443",
      "6. Test API Server (External): curl -k https://${var.master_lb_public_ip}:6443"
      ] : [
      "1. SSH to master-1: ssh -i ${var.ssh_key_path} ubuntu@${length(var.master_public_ips) > 0 ? var.master_public_ips[0] : ""}",
      "2. Run installation: bash /home/ubuntu/scripts/install_kpaas.sh",
      "3. Or run step by step:",
      "   - bash /home/ubuntu/scripts/01.all_common_setting.sh",
      "   - bash /home/ubuntu/scripts/03.master_nfs_server.sh",
      "   - bash /home/ubuntu/scripts/04.master_ssh_setting.sh",
      "   - bash /home/ubuntu/scripts/05.master_install_k-pass.sh"
    ]
    installation_time = var.auto_install_kpaas ? "Approximately 20-40 minutes" : "N/A"
  }
}

output "generated_scripts" {
  description = "List of generated script files"
  value = [
    local_file.cp_cluster_vars.filename,
    local_file.global_variable.filename,
    local_file.master_nfs_server.filename,
    local_file.master_ssh_setting.filename,
    local_file.all_common_setting.filename,
    local_file.master_install_kpaas.filename,
    local_file.master_install_portal.filename
  ]
}
