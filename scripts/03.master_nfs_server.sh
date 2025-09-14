#!/usr/bin/env bash
set -e

# https://github.com/K-PaaS/container-platform/blob/master/install-guide/nfs-server-install-guide.md

# NFS Server Install
sudo apt-get install -y nfs-common nfs-kernel-server portmap
sudo mkdir -p /home/share/nfs
sudo chmod -R 777 /home/share/nfs

## It needs to be reconfigured according to the changed IP range.
sudo cat <<EOF | sudo tee /etc/exports
## 형식 : [/shared_directory] [access_IP] [option]
## 예시 : /home/share/nfs 10.0.0.1(rw,no_root_squash,async)
/home/share/nfs master01(rw,no_root_squash,async)
/home/share/nfs master02(rw,no_root_squash,async)
/home/share/nfs worker01(rw,no_root_squash,async)
/home/share/nfs worker02(rw,no_root_squash,async)
EOF

# restart
sudo /etc/init.d/nfs-kernel-server restart
sudo systemctl restart portmap
