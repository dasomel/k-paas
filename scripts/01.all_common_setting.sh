#!/usr/bin/env bash
set -e

# Global Variable Setting
source /vagrant/00.global_variable.sh

sudo apt-get update
sudo apt-get install -y build-essential dkms linux-headers-"$(uname -r)" cloud-guest-utils

# ============================================================
# Disk Expansion: Vagrantfile에서 disk size를 늘려도 VM 내부에서
# 자동 적용되지 않으므로 LVM 확장 명령을 수동 실행
# ============================================================
echo ">>> Expanding disk to use full allocated space..."

# 1. 파티션 확장 (sda3가 LVM 파티션)
sudo growpart /dev/sda 3 2>/dev/null || echo "Partition already at max size or growpart failed"

# 2. LVM Physical Volume 확장
sudo pvresize /dev/sda3 2>/dev/null || echo "PV resize skipped"

# 3. LVM Logical Volume 확장 (100% 여유 공간 사용)
sudo lvextend -l +100%FREE /dev/ubuntu-vg/ubuntu-lv 2>/dev/null || echo "LV already at max size"

# 4. 파일시스템 확장 (ext4)
sudo resize2fs /dev/ubuntu-vg/ubuntu-lv 2>/dev/null || echo "Filesystem resize skipped"

echo ">>> Disk expansion complete. Current disk usage:"
df -h /

# timezone change
sudo timedatectl set-timezone Asia/Seoul

# ubuntu ssh setting
sudo tee /etc/ssh/sshd_config > /dev/null <<EOF
Port 22
PermitRootLogin yes
PasswordAuthentication yes
PubkeyAuthentication yes
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding yes
PrintMotd no
AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/openssh/sftp-server
EOF
sudo systemctl restart ssh.service

# hosts setting
sudo cat << EOF | sudo tee -a /etc/hosts
$CLUSTER_ENDPOINT cluster-endpoint
$MASTER01 master01
$MASTER02 master02
$WORKER01 worker01
$WORKER02 worker02
$LB01 lb01
$LB02 lb02
$PORTAL_HOST_IP $PORTAL_HOST_DOMAIN
$PORTAL_HOST_IP openbao.$PORTAL_HOST_DOMAIN
$PORTAL_HOST_IP harbor.$PORTAL_HOST_DOMAIN
$PORTAL_HOST_IP keycloak.$PORTAL_HOST_DOMAIN
$PORTAL_HOST_IP portal.$PORTAL_HOST_DOMAIN
$PORTAL_HOST_IP chartmuseum.$PORTAL_HOST_DOMAIN
EOF
