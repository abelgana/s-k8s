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
(
cd /home || exit
tar -xf /home/core/vagrant/vault.tar
cp /home/core/vagrant/vault1Config.json /etc/vault/config/config.json
cp /home/vault/ssl/vault1/api.pem /etc/vault/ssl/
cp /home/vault/ssl/vault1/api-key.pem /etc/vault/ssl/
cp /home/core/vagrant/vault-01.service /etc/systemd/system/vault.service
)
systemctl start vault
