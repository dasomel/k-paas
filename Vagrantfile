# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANT_BOX      = 'ubuntu/jammy64' #22.04
VAGRANT_PROVIDER = 'virtualbox'
NODE_IP          = "192.168.100."

Vagrant.configure("2") do |config|
  config.vm.post_up_message  = "K-PaaS v1.5.1 Local Install 1.0"
  config.vbguest.auto_update = false
  config.vm.provider VAGRANT_PROVIDER do |vb|
    vb.cpus = 2
    vb.memory = 4096
    vb.customize ['modifyvm', :id, '--nictype1', 'virtio']
    vb.customize ['modifyvm', :id, '--nictype2', 'virtio']
  end

  # Worker Node
  (1..2).each do |i|
    config.vm.define "worker0#{i}" do |node|
      node.vm.box = VAGRANT_BOX
      node.vm.hostname = "worker0#{i}"
      node.vm.network "private_network", ip: NODE_IP + "11#{i}" # enp0s8
      node.vm.provision "shell", inline: "echo =============== START Worker0#{i} - COMMON_SETTING ======================"
      node.vm.provision "shell", path: "./scripts/01.all_common_setting.sh", privileged: false
      node.vm.provision "shell", inline: "echo =============== E N D Worker0#{i} - COMMON_SETTING ======================"
    end
  end

  # Master Node
  (1..2).reverse_each do |i|
    config.vm.define "master0#{i}" do |node|
      node.vm.box = VAGRANT_BOX
      node.vm.hostname = "master0#{i}"
      node.vm.network "private_network", ip: NODE_IP + "10#{i}" # enp0s8
      node.vm.provision "shell", inline: "echo =============== START master0#{i} - COMMON_SETTING ======================"
      node.vm.provision "shell", path: "./scripts/01.all_common_setting.sh", privileged: false
      node.vm.provision "shell", inline: "echo =============== E N D master0#{i} - COMMON_SETTING ======================"
      node.vm.provision "shell", inline: "echo =============== START master0#{i} - haproxy_SETTING ====================="
      node.vm.provision "shell", path: "./scripts/03.master_all_haproxy.sh", privileged: false
      node.vm.provision "shell", inline: "echo =============== E N D master0#{i} - haproxy_SETTING ====================="
      if "#{i}" == "1"
        node.vm.provision "shell", inline: "echo ================ START master0#{i} - ssh_setting ======================"
        node.vm.provision "shell", path: "./scripts/04.master_ssh_setting.sh", privileged: false
        node.vm.provision "shell", inline: "echo ================ E N D master0#{i} - ssh_setting ======================"
        node.vm.provision "shell", inline: "echo ================ START master0#{i} - nfs_server ======================="
        node.vm.provision "shell", path: "./scripts/05.master_nfs_server.sh", privileged: false
        node.vm.provision "shell", inline: "echo ================ E N D master0#{i} - nfs_server ======================="
        node.vm.provision "shell", inline: "echo ============== START master0#{i} - install_k-pass ====================="
        node.vm.provision "shell", path: "./scripts/06.master_install_k-pass.sh", privileged: false
        node.vm.provision "shell", inline: "echo ============== E N D master0#{i} - install_k-pass ====================="
        node.vm.provision "shell", inline: "echo ========== START master0#{i} - install_k-pass_portal =================="
        node.vm.provision "shell", path: "./scripts/07.master_install_k-pass_portal.sh", privileged: false
        node.vm.provision "shell", inline: "echo ========== E N D master0#{i} - install_k-pass_portal =================="
      end
    end
  end

end
