#!/usr/bin/env bash

# Global Variable Setting
source /vagrant/00.global_variable.sh

sudo apt-get install -y sshpass

ssh-keygen -t rsa-sha2-512 -b 4096 -N '' -f ~/.ssh/id_rsa <<< n

# public key registration
# shellcheck disable=SC2129
ssh-keyscan -t ecdsa "$MASTER01" >> ~/.ssh/known_hosts
ssh-keyscan -t ecdsa "$MASTER02" >> ~/.ssh/known_hosts
ssh-keyscan -t ecdsa "$WORKER01" >> ~/.ssh/known_hosts
ssh-keyscan -t ecdsa "$WORKER02" >> ~/.ssh/known_hosts

# ssh key copy
sshpass -pvagrant ssh-copy-id -i ~/.ssh/id_rsa.pub vagrant@"$MASTER01"
sshpass -pvagrant ssh-copy-id -i ~/.ssh/id_rsa.pub vagrant@"$MASTER02"
sshpass -pvagrant ssh-copy-id -i ~/.ssh/id_rsa.pub vagrant@"$WORKER01"
sshpass -pvagrant ssh-copy-id -i ~/.ssh/id_rsa.pub vagrant@"$WORKER02"

# Do not apply in operational environments
# fatal: Failed to connect to the host via ssh: Host key verification failed.
cat << EOF | tee -a ~/.ssh/config
Host *
    StrictHostKeyChecking no
EOF
