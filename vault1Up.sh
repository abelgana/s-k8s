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
cp /tmp/home/vault/ssl/vault1/api.pem /etc/vault/ssl/
cp /tmp/home/vault/ssl/vault1/api-key.pem /etc/vault/ssl/
cp /tmp/home/etcd/ca.pem /etc/ssl/etcd/ssl/ca.pem
)
cp vault/vault1Config.json /etc/vault/config/config.json
cp vault/vault-01.service /etc/systemd/system/vault.service
systemctl start vault
