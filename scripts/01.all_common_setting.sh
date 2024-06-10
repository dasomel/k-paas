#!/usr/bin/env bash
set -e

# Global Variable Setting
source /vagrant/scripts/00.global_variable.sh

sudo apt-get update

# timezone change
sudo timedatectl set-timezone Asia/Seoul

# ubuntu 22.04 ssh setting
sudo sed -i 's/#Port 22/Port 22/'                                       /etc/ssh/sshd_config
sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g'  /etc/ssh/sshd_config.d/60-cloudimg-settings.conf
sudo systemctl restart ssh

# hosts setting
sudo cat << EOF | sudo tee -a /etc/hosts
$CLUSTER_ENDPOINT cluster-endpoint
$MASTER01 master01
$MASTER02 master02
$WORKER01 worker01
$WORKER02 worker02
$PORTAL_HOST_IP $PORTAL_HOST_DOMAIN
$PORTAL_HOST_IP vault.$PORTAL_HOST_DOMAIN
$PORTAL_HOST_IP harbor.$PORTAL_HOST_DOMAIN
$PORTAL_HOST_IP keycloak.$PORTAL_HOST_DOMAIN
$PORTAL_HOST_IP portal.$PORTAL_HOST_DOMAIN
EOF
