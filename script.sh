#!/bin/sh

mkdir /etc/vault
cp vault/vault_temp_config.json /etc/vault/vault_temp_config.json
docker pull vault:0.9.0
docker run -itd --cap-add=IPC_LOCK --name vault -p 8200:8200  -v /etc/vault:/etc/vault vault:0.9.0 server -config=/etc/vault/vault_temp_config.json
sleep 10

allkeys=$(curl -H "Content-Type: application/json" --request PUT --data @vault/init.json http://127.0.0.1:8200/v1/sys/init)
key=$(echo "$allkeys" | jq .'keys'[0])
root_token=$(echo "$allkeys" | jq -r .'root_token')
curl -H "Content-Type: application/json" --request POST -d "{ \"key\": $key }" http://127.0.0.1:8200/v1/sys/unseal
curl -H "Content-Type: application/json" -H "X-Vault-Token: $root_token" -X POST -d @vault/mount.json http://0.0.0.0:8200/v1/sys/mounts/vault
curl -H "Content-Type: application/json" -H "X-Vault-Token: $root_token" -X POST -d @vault/mount.json http://0.0.0.0:8200/v1/sys/mounts/etcd
curl -H "Content-Type: application/json" -H "X-Vault-Token: $root_token" -X POST -d @vault/auth.json http://0.0.0.0:8200/v1/sys/auth/userpass
curl -H "Content-Type: application/json" -H "X-Vault-Token: $root_token" -X PUT -d @vault/roleVault.json http://0.0.0.0:8200/v1/sys/policy/vault
curl -H "Content-Type: application/json" -H "X-Vault-Token: $root_token" -X PUT -d @vault/roleEtcd.json http://0.0.0.0:8200/v1/sys/policy/etcd
curl -H "Content-Type: application/json" -H "X-Vault-Token: $root_token" -X POST -d @vault/rolesVault.json http://0.0.0.0:8200/v1/vault/roles/vault
curl -H "Content-Type: application/json" -H "X-Vault-Token: $root_token" -X POST -d @vault/rolesEtcd.json http://0.0.0.0:8200/v1/etcd/roles/etcd
curl -H "Content-Type: application/json" -H "X-Vault-Token: $root_token" -X POST -d @vault/userVault.json http://0.0.0.0:8200/v1/auth/userpass/users/vault
curl -H "Content-Type: application/json" -H "X-Vault-Token: $root_token" -X POST -d @vault/userEtcd.json http://0.0.0.0:8200/v1/auth/userpass/users/etcd

vaultpems=$(curl -H "Content-Type: application/json" -H "X-Vault-Token: $root_token" -X POST -d @vault/genCertVault.json http://0.0.0.0:8200/v1/vault/root/generate/exported)
etcdpems=$(curl -H "Content-Type: application/json" -H "X-Vault-Token: $root_token" -X POST -d @vault/genCertEtcd.json http://0.0.0.0:8200/v1/etcd/root/generate/exported)
(
cd /home || exit
mkdir -p vault
cd vault || exit
echo "$vaultpems" | jq -r ."data.certificate" | sed 's/\\n/\n\r/g' > ca.pem
echo "$vaultpems" | jq -r ."data.private_key" | sed 's/\\n/\n\r/g' > ca-key.pem
)
(
cd /home || exit
mkdir -p etcd
cd etcd || exit
echo "$etcdpems" | jq -r ."data.certificate" | sed 's/\\n/\n\r/g' > ca.pem
echo "$etcdpems" | jq -r ."data.private_key" | sed 's/\\n/\n\r/g' > ca-key.pem
)

vaultToken=$(curl -H "Content-Type: application/json" -X POST -d "{\"password\": \"vault\"}" http://0.0.0.0:8200/v1/auth/userpass/login/vault | jq -r ."auth.client_token")
certVault1=$(curl -H "Content-Type: application/json" -H "X-Vault-Token: $vaultToken" -d @vault/issueCertVault1.json -X POST http://0.0.0.0:8200/v1/vault/issue/vault)
certVault2=$(curl -H "Content-Type: application/json" -H "X-Vault-Token: $vaultToken" -d @vault/issueCertVault2.json -X POST http://0.0.0.0:8200/v1/vault/issue/vault)
(
cd /home || exit
mkdir -p vault/ssl/vault1
cd vault/ssl/vault1 || exit
echo "$certVault1" | jq -r ."data.certificate" | sed 's/\\n/\n\r/g' > api.pem
echo "$certVault1" | jq -r ."data.private_key" | sed 's/\\n/\n\r/g' > api-key.pem
echo "$certVault1" | jq -r ."data.issuing_ca" | sed 's/\\n/\n\r/g' > ca.pem
echo "$certVault1" | jq -r ."data.serial_number" | sed 's/\\n/\n\r/g' > api.serial
)
(
cd /home || exit
mkdir -p vault/ssl/vault2
cd vault/ssl/vault2 || exit
echo "$certVault2" | jq -r ."data.certificate" | sed 's/\\n/\n\r/g' > api.pem
echo "$certVault2" | jq -r ."data.private_key" | sed 's/\\n/\n\r/g' > api-key.pem
echo "$certVault2" | jq -r ."data.issuing_ca" | sed 's/\\n/\n\r/g' > ca.pem
echo "$certVault2" | jq -r ."data.serial_number" | sed 's/\\n/\n\r/g' > api.serial
)

etcdToken=$(curl -H "Content-Type: application/json" -X POST -d "{\"password\": \"etcd\"}" http://0.0.0.0:8200/v1/auth/userpass/login/etcd | jq -r ."auth.client_token")
certEtcd1=$(curl -H "Content-Type: application/json" -H "X-Vault-Token: $etcdToken" -d @vault/issueCertEtcd1.json -X POST http://0.0.0.0:8200/v1/etcd/issue/etcd)
certEtcd2=$(curl -H "Content-Type: application/json" -H "X-Vault-Token: $etcdToken" -d @vault/issueCertEtcd2.json -X POST http://0.0.0.0:8200/v1/etcd/issue/etcd)
certEtcd3=$(curl -H "Content-Type: application/json" -H "X-Vault-Token: $etcdToken" -d @vault/issueCertEtcd3.json -X POST http://0.0.0.0:8200/v1/etcd/issue/etcd)
(
cd /home || exit
mkdir -p etcd/ssl/etcd1
cd etcd/ssl/etcd1 || exit
echo "$certEtcd1" | jq -r ."data.certificate" | sed 's/\\n/\n\r/g' > etcd-01.pem
echo "$certEtcd1" | jq -r ."data.private_key" | sed 's/\\n/\n\r/g' > etcd-01-key.pem
echo "$certEtcd1" | jq -r ."data.issuing_ca" | sed 's/\\n/\n\r/g' > ca.pem
echo "$certEtcd1" | jq -r ."data.serial_number" | sed 's/\\n/\n\r/g' > etcd-01.serial
)
(
cd /home || exit
mkdir -p etcd/ssl/etcd2
cd etcd/ssl/etcd2 || exit
echo "$certEtcd2" | jq -r ."data.certificate" | sed 's/\\n/\n\r/g' > etcd-02.pem
echo "$certEtcd2" | jq -r ."data.private_key" | sed 's/\\n/\n\r/g' > etcd-02-key.pem
echo "$certEtcd2" | jq -r ."data.issuing_ca" | sed 's/\\n/\n\r/g' > ca.pem
echo "$certEtcd2" | jq -r ."data.serial_number" | sed 's/\\n/\n\r/g' > etcd-02.serial
)
(
cd /home || exit
mkdir -p etcd/ssl/etcd3
cd etcd/ssl/etcd3 || exit
echo "$certEtcd3" | jq -r ."data.certificate" | sed 's/\\n/\n\r/g' > etcd-03.pem
echo "$certEtcd3" | jq -r ."data.private_key" | sed 's/\\n/\n\r/g' > etcd-03-key.pem
echo "$certEtcd3" | jq -r ."data.issuing_ca" | sed 's/\\n/\n\r/g' > ca.pem
echo "$certEtcd3" | jq -r ."data.serial_number" | sed 's/\\n/\n\r/g' > etcd-03.serial
)

mkdir certs
tar -cf certs/etcd.tar /home/etcd
tar -cf certs/vault.tar /home/vault
