#!/bin/sh
cd /home/core/vagrant || exit
mkdir /etc/vault
cp vault_temp_config.json /etc/vault/vault_temp_config.json
docker pull vault:0.9.0
docker rm -f vault
docker run -itd --cap-add=IPC_LOCK --name vault -p 8200:8200  -v /etc/vault:/etc/vault vault:0.9.0 server -config=/etc/vault/vault_temp_config.json
sleep 10

allkeys=$(curl -H "Content-Type: application/json" --request PUT --data @init.json http://127.0.0.1:8200/v1/sys/init)
key=$(echo "$allkeys" | jq .'keys'[0])
root_token=$(echo "$allkeys" | jq -r .'root_token')
curl -H "Content-Type: application/json" --request POST -d "{ \"key\": $key }" http://127.0.0.1:8200/v1/sys/unseal
curl -H "Content-Type: application/json" -H "X-Vault-Token: $root_token" -X POST -d @mount.json http://0.0.0.0:8200/v1/sys/mounts/vault
curl -H "Content-Type: application/json" -H "X-Vault-Token: $root_token" -X POST -d @mount.json http://0.0.0.0:8200/v1/sys/mounts/etcd
curl -H "Content-Type: application/json" -H "X-Vault-Token: $root_token" -X POST -d @auth.json http://0.0.0.0:8200/v1/sys/auth/userpass
curl -H "Content-Type: application/json" -H "X-Vault-Token: $root_token" -X PUT -d @roleVault.json http://0.0.0.0:8200/v1/sys/policy/vault
curl -H "Content-Type: application/json" -H "X-Vault-Token: $root_token" -X PUT -d @roleEtcd.json http://0.0.0.0:8200/v1/sys/policy/etcd
curl -H "Content-Type: application/json" -H "X-Vault-Token: $root_token" -X POST -d @rolesVault.json http://0.0.0.0:8200/v1/vault/roles/vault
curl -H "Content-Type: application/json" -H "X-Vault-Token: $root_token" -X POST -d @rolesEtcd.json http://0.0.0.0:8200/v1/etcd/roles/etcd
curl -H "Content-Type: application/json" -H "X-Vault-Token: $root_token" -X POST -d @userVault.json http://0.0.0.0:8200/v1/auth/userpass/users/vault
curl -H "Content-Type: application/json" -H "X-Vault-Token: $root_token" -X POST -d @userEtcd.json http://0.0.0.0:8200/v1/auth/userpass/users/etcd

vaultpems=$(curl -H "Content-Type: application/json" -H "X-Vault-Token: $root_token" -X POST -d @genCertVault.json http://0.0.0.0:8200/v1/vault/root/generate/exported)
etcdpems=$(curl -H "Content-Type: application/json" -H "X-Vault-Token: $root_token" -X POST -d @genCertEtcd.json http://0.0.0.0:8200/v1/etcd/root/generate/exported)
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
certVault1=$(curl -H "Content-Type: application/json" -H "X-Vault-Token: $vaultToken" -d @issueCertVault1.json -X POST http://0.0.0.0:8200/v1/vault/issue/vault)
certVault2=$(curl -H "Content-Type: application/json" -H "X-Vault-Token: $vaultToken" -d @issueCertVault2.json -X POST http://0.0.0.0:8200/v1/vault/issue/vault)
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
certEtcd1=$(curl -H "Content-Type: application/json" -H "X-Vault-Token: $etcdToken" -d @issueCertEtcd1.json -X POST http://0.0.0.0:8200/v1/etcd/issue/etcd)
certEtcd2=$(curl -H "Content-Type: application/json" -H "X-Vault-Token: $etcdToken" -d @issueCertEtcd2.json -X POST http://0.0.0.0:8200/v1/etcd/issue/etcd)
certEtcd3=$(curl -H "Content-Type: application/json" -H "X-Vault-Token: $etcdToken" -d @issueCertEtcd3.json -X POST http://0.0.0.0:8200/v1/etcd/issue/etcd)
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

nodeToken=$(curl -H "Content-Type: application/json" -X POST -d "{\"password\": \"etcd\"}" http://0.0.0.0:8200/v1/auth/userpass/login/etcd | jq -r ."auth.client_token")
certMaster1=$(curl -H "Content-Type: application/json" -H "X-Vault-Token: $nodeToken" -d @issueCertMaster1.json -X POST http://0.0.0.0:8200/v1/etcd/issue/etcd)
certMaster2=$(curl -H "Content-Type: application/json" -H "X-Vault-Token: $nodeToken" -d @issueCertMaster2.json -X POST http://0.0.0.0:8200/v1/etcd/issue/etcd)
certMaster3=$(curl -H "Content-Type: application/json" -H "X-Vault-Token: $nodeToken" -d @issueCertMaster3.json -X POST http://0.0.0.0:8200/v1/etcd/issue/etcd)
certWorker1=$(curl -H "Content-Type: application/json" -H "X-Vault-Token: $nodeToken" -d @issueCertWorker1.json -X POST http://0.0.0.0:8200/v1/etcd/issue/etcd)
certWorker2=$(curl -H "Content-Type: application/json" -H "X-Vault-Token: $nodeToken" -d @issueCertWorker2.json -X POST http://0.0.0.0:8200/v1/etcd/issue/etcd)
certWorker3=$(curl -H "Content-Type: application/json" -H "X-Vault-Token: $nodeToken" -d @issueCertWorker3.json -X POST http://0.0.0.0:8200/v1/etcd/issue/etcd)
(
cd /home || exit
mkdir -p node/ssl/master1
cd node/ssl/master1 || exit
echo "$certMaster1" | jq -r ."data.certificate" | sed 's/\\n/\n\r/g' > api.pem
echo "$certMaster1" | jq -r ."data.private_key" | sed 's/\\n/\n\r/g' > api-key.pem
echo "$certMaster1" | jq -r ."data.issuing_ca" | sed 's/\\n/\n\r/g' > ca.pem
echo "$certMaster1" | jq -r ."data.serial_number" | sed 's/\\n/\n\r/g' > api.serial
)
(
cd /home || exit
mkdir -p node/ssl/master2
cd node/ssl/master2 || exit
echo "$certMaster2" | jq -r ."data.certificate" | sed 's/\\n/\n\r/g' > api.pem
echo "$certMaster2" | jq -r ."data.private_key" | sed 's/\\n/\n\r/g' > api-key.pem
echo "$certMaster2" | jq -r ."data.issuing_ca" | sed 's/\\n/\n\r/g' > ca.pem
echo "$certMaster2" | jq -r ."data.serial_number" | sed 's/\\n/\n\r/g' > api.serial
)
(
cd /home || exit
mkdir -p node/ssl/master3
cd node/ssl/master3 || exit
echo "$certMaster3" | jq -r ."data.certificate" | sed 's/\\n/\n\r/g' > api.pem
echo "$certMaster3" | jq -r ."data.private_key" | sed 's/\\n/\n\r/g' > api-key.pem
echo "$certMaster3" | jq -r ."data.issuing_ca" | sed 's/\\n/\n\r/g' > ca.pem
echo "$certMaster3" | jq -r ."data.serial_number" | sed 's/\\n/\n\r/g' > api.serial
)
(
cd /home || exit
mkdir -p node/ssl/worker1
cd node/ssl/worker1 || exit
echo "$certWorker1" | jq -r ."data.certificate" | sed 's/\\n/\n\r/g' > api.pem
echo "$certWorker1" | jq -r ."data.private_key" | sed 's/\\n/\n\r/g' > api-key.pem
echo "$certWorker1" | jq -r ."data.issuing_ca" | sed 's/\\n/\n\r/g' > ca.pem
echo "$certWorker1" | jq -r ."data.serial_number" | sed 's/\\n/\n\r/g' > api.serial
)
(
cd /home || exit
mkdir -p node/ssl/worker2
cd node/ssl/worker2 || exit
echo "$certWorker2" | jq -r ."data.certificate" | sed 's/\\n/\n\r/g' > api.pem
echo "$certWorker2" | jq -r ."data.private_key" | sed 's/\\n/\n\r/g' > api-key.pem
echo "$certWorker2" | jq -r ."data.issuing_ca" | sed 's/\\n/\n\r/g' > ca.pem
echo "$certWorker2" | jq -r ."data.serial_number" | sed 's/\\n/\n\r/g' > api.serial
)
(
cd /home || exit
mkdir -p node/ssl/worker3
cd node/ssl/worker3 || exit
echo "$certWorker3" | jq -r ."data.certificate" | sed 's/\\n/\n\r/g' > api.pem
echo "$certWorker3" | jq -r ."data.private_key" | sed 's/\\n/\n\r/g' > api-key.pem
echo "$certWorker3" | jq -r ."data.issuing_ca" | sed 's/\\n/\n\r/g' > ca.pem
echo "$certWorker3" | jq -r ."data.serial_number" | sed 's/\\n/\n\r/g' > api.serial
)
(
cd /home || exit
tar -cf etcd.tar etcd
tar -cf vault.tar vault
tar -cf node.tar node
cp ./*.tar core/vagrant/
)
