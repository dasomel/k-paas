# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANT_BOX         = 'dasomel/ubuntu-24.04'
VAGRANT_BOX_VERSION = "0.1.0"
VAGRANT_PROVIDER    = ENV['VAGRANT_PROVIDER'] || 'vmware_desktop'
NODE_IP             = "192.168.100."

Vagrant.configure("2") do |config|
  config.vm.post_up_message  = "K-PaaS lite 2.2.0"
  config.vm.box_version = VAGRANT_BOX_VERSION
  config.vm.synced_folder "./scripts", "/vagrant", type: "rsync"

  config.vm.provider :virtualbox do |vb|
    vb.cpus = 2
    vb.memory = 4096
    vb.customize ['modifyvm', :id, '--nictype1', 'virtio']
    vb.customize ['modifyvm', :id, '--nictype2', 'virtio']
    vb.customize ["modifyvm", :id, "--ioapic", "on"]
    vb.customize ["modifyvm", :id, "--accelerate3d", "off"]
  end
  config.vm.provider :vmware_desktop do |vb|
    vb.cpus = 2
    vb.memory = 4096
  end

  # Load Balancer Nodes
  (1..2).each do |i|
    config.vm.define "lb0#{i}" do |node|
      node.vm.box = VAGRANT_BOX
      node.vm.hostname = "lb0#{i}"
      node.vm.network "private_network", ip: NODE_IP + "12#{i}"
      node.vm.provider :virtualbox do |vb|
        vb.cpus = 1
        vb.memory = 1024
      end
      node.vm.provider :vmware_desktop do |vb|
        vb.cpus = 1
        vb.memory = 1024
      end
      node.vm.provision "shell", inline: "echo =============== START lb0#{i} - COMMON_SETTING ======================"
      node.vm.provision "shell", path: "./scripts/01.all_common_setting.sh", privileged: false
      node.vm.provision "shell", inline: "echo =============== E N D lb0#{i} - COMMON_SETTING ======================"
      node.vm.provision "shell", inline: "echo =============== START lb0#{i} - haproxy_SETTING ====================="
      node.vm.provision "shell", path: "./scripts/02.lb_haproxy.sh", privileged: false
      node.vm.provision "shell", inline: "echo =============== E N D lb0#{i} - haproxy_SETTING ====================="
    end
  end

  # Worker Nodes
  (1..2).each do |i|
    config.vm.define "worker0#{i}" do |node|
      node.vm.box = VAGRANT_BOX
      node.vm.hostname = "worker0#{i}"
      node.vm.network "private_network", ip: NODE_IP + "11#{i}"
      node.vm.disk :disk, size: "50GB", primary: true
      node.vm.provider :virtualbox do |vb|
        vb.cpus = 6
        vb.memory = 6 * 1024
      end
      node.vm.provider :vmware_desktop do |vb|
        vb.cpus = 6
        vb.memory = 6 * 1024
      end

      node.vm.provision "shell", inline: "echo =============== START worker0#{i} - COMMON_SETTING ==================="
      node.vm.provision "shell", inline: "echo =============== START Worker0#{i} - COMMON_SETTING ==================="
      node.vm.provision "shell", path: "./scripts/01.all_common_setting.sh", privileged: false
      node.vm.provision "shell", inline: "echo =============== E N D Worker0#{i} - COMMON_SETTING ==================="
    end
  end

  # Master Nodes
  (1..2).reverse_each do |i|
    config.vm.define "master0#{i}" do |node|
      node.vm.box = VAGRANT_BOX
      node.vm.hostname = "master0#{i}"
      node.vm.network "private_network", ip: NODE_IP + "10#{i}"
      node.vm.disk :disk, size: "40GB", primary: true
      node.vm.provider :virtualbox do |vb|
        vb.cpus = 2
        vb.memory = 4 * 1024
      end

      node.vm.provider :vmware_desktop do |vb|
        vb.cpus = 2
        vb.memory = 4 * 1024
      end

      node.vm.provision "shell", inline: "echo =============== START master0#{i} - COMMON_SETTING ==================="
      node.vm.provision "shell", path: "./scripts/01.all_common_setting.sh", privileged: false
      node.vm.provision "shell", inline: "echo =============== E N D master0#{i} - COMMON_SETTING ==================="
      if "#{i}" == "1"
          node.vm.provision "shell", inline: "echo ============== START master0#{i} - NFS_SERVER ===================="
          node.vm.provision "shell", path: "./scripts/03.master_nfs_server.sh", privileged: false
          node.vm.provision "shell", inline: "echo ============== E N D master0#{i} - NFS_SERVER ===================="
          node.vm.provision "shell", inline: "echo ================ START master0#{i} - SSH_SETTING ================="
          node.vm.provision "shell", path: "./scripts/04.master_ssh_setting.sh", privileged: false
          node.vm.provision "shell", inline: "echo ================ E N D master0#{i} - SSH_SETTING ================="
          node.vm.provision "shell", inline: "echo ================ START master0#{i} - INSTALL_K-PAAS =============="
          node.vm.provision "shell", path: "./scripts/05.master_install_k-pass.sh", privileged: false
          node.vm.provision "shell", inline: "echo ================ E N D master0#{i} - INSTALL_K-PASS =============="
          node.vm.provision "shell", inline: "echo ================ START master0#{i} - INSTALL_K-PASS_PORTAL ======="
          node.vm.provision "shell", path: "./scripts/06.master_install_k-pass_portal.sh", privileged: false
          node.vm.provision "shell", inline: "echo ================ E N D master0#{i} - INSTALL_K-PASS_PORTAL ======="
      end
    end
  end

end
