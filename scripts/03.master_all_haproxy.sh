#!/usr/bin/env bash
set -e

# https://github.com/K-PaaS/container-platform/blob/master/install-guide/standalone/cp-cluster-install-single.md
# https://hkjeon2.tistory.com/134

# Global Variable Setting
source /vagrant/scripts/00.global_variable.sh

# keepalived install
sudo apt-get install -y keepalived

sudo echo 'net.ipv4.ip_nonlocal_bind=1' | sudo tee -a /etc/sysctl.conf
sudo echo 'net.ipv4.ip_forward=1'       | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Keepalived setting
if [ $(hostname) == master01 ]; then
STATE=MASTER
UNICAST_SRC_IP=$MASTER01
UNICAST_PEER=$MASTER02
PRIORITY=110
elif [ $(hostname) == master02 ]; then
STATE=BACKUP
UNICAST_SRC_IP=$MASTER02
UNICAST_PEER=$MASTER01
PRIORITY=109
fi
INTERFACE_NAME=$VM_INTERFACE_NAME

sudo cat << EOF | sudo tee -a /etc/keepalived/keepalived.conf
vrrp_instance VI_1 {
  state $STATE
  interface $INTERFACE_NAME
  virtual_router_id 51
  priority $PRIORITY
  advert_int 1

  authentication {
    auth_type PASS
    auth_pass 1111
  }

  virtual_ipaddress {
    $CLUSTER_ENDPOINT
  }
}
EOF

sudo systemctl start keepalived
sudo systemctl enable keepalived

# HAProxy install
sudo apt-get install -y haproxy

sudo cat << EOF | sudo tee -a /etc/haproxy/haproxy.cfg
listen kubernetes-apiserver-https
  bind $CLUSTER_ENDPOINT:6443
  mode tcp
  option log-health-checks
  timeout client 3h
  timeout server 3h
  server master01 $MASTER01:6443 check check-ssl verify none inter 10000
  server master02 $MASTER02:6443 check check-ssl verify none inter 10000
  balance roundrobin
EOF

sudo systemctl start haproxy
sudo systemctl enable haproxy
