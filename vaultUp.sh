#!/bin/sh
mkdir -p /etc/vault/ssl
mkdir -p /etc/vault/config
mkdir -p /etc/vault/secrets
mkdir -p /etc/vault/secrets
mkdir -p /var/log/vault
mkdir -p /var/lib/vault
useradd -U -m vault -G sudo
chown -R vault /etc/vault/
chown -R vault /var/log/vault
chown -R vault /var/lib/vault
mkdir -p /etc/ssl/etcd/ssl/
(
tar -xf certs/vault.tar -C /tmp
tar -xf certs/etcd.tar -C /tmp
cp /tmp/home/vault/ssl/api-${HOSTNAME}.pem /etc/vault/ssl/api.pem
cp /tmp/home/vault/ssl/api-${HOSTNAME}-key.pem /etc/vault/ssl/api-key.pem
cp /tmp/home/vault/ssl/api-${HOSTNAME}.pem /etc/vault/ssl/aca.pem
cp /tmp/home/etcd/ca.pem /etc/ssl/etcd/ssl/ca.pem
)
cp vault/vaultConfig.json /etc/vault/config/config.json
export NODE_IP=$(/usr/bin/ip -o -4 addr list eth1 | awk '{print $4}' | cut -d/ -f1)
envsubst < vault/vaultConfig.json > /etc/vault/config/config.json 
cp vault/vault.service /etc/systemd/system/vault.service
systemctl daemon-reload
systemctl start vault.service
systemctl start vault.service
