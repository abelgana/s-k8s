#!/bin/sh

allkeys=$(curl --cacert /home/vault/ssl/vault2/ca.pem -H "Content-Type: application/json" --request POST --data @init.json https://127.0.0.1:8200/v1/sys/init)
key=$(echo "$allkeys" | jq .'keys'[0])
root_token=$(echo "$allkeys" | jq -r .'root_token')

curl --cacert /home/vault/ssl/vault1/ca.pem -H "Content-Type: application/json" --request POST -d "{ \"key\": $key }" https://127.0.0.1:8200/v1/sys/unseal
curl --cacert /home/vault/ssl/vault2/ca.pem -H "Content-Type: application/json" --request POST -d "{ \"key\": $key }" https://172.17.8.52:8200/v1/sys/unseal
curl --cacert /home/vault/ssl/vault1/ca.pem -H "Content-Type: application/json" https://127.0.0.1:8200/v1/sys/health
curl --cacert /home/vault/ssl/vault1/ca.pem -H "Content-Type: application/json" https://172.17.8.52:8200/v1/sys/health

curl --cacert /home/vault/ssl/vault1/ca.pem -H "Content-Type: application/json" -H "X-Vault-Token: $root_token" -X POST -d @mount.json https://127.0.0.1:8200/v1/sys/mounts/vault
curl --cacert /home/vault/ssl/vault1/ca.pem -H "Content-Type: application/json" -H "X-Vault-Token: $root_token" -X POST -d @mount.json https://127.0.0.1:8200/v1/sys/mounts/kube

curl --cacert /home/vault/ssl/vault1/ca.pem -H "Content-Type: application/json" -H "X-Vault-Token: $root_token" -X PUT -d @roleVault.json https://127.0.0.1:8200/v1/sys/policy/vault
curl --cacert /home/vault/ssl/vault1/ca.pem -H "Content-Type: application/json" -H "X-Vault-Token: $root_token" -X PUT -d @roleEtcd.json https://127.0.0.1:8200/v1/sys/policy/etcd
curl --cacert /home/vault/ssl/vault1/ca.pem -H "Content-Type: application/json" -H "X-Vault-Token: $root_token" -X PUT -d @roleKubeMaster.json https://127.0.0.1:8200/v1/sys/policy/kube-master
curl --cacert /home/vault/ssl/vault1/ca.pem -H "Content-Type: application/json" -H "X-Vault-Token: $root_token" -X PUT -d @roleKubeNode.json https://127.0.0.1:8200/v1/sys/policy/kube-node
curl --cacert /home/vault/ssl/vault1/ca.pem -H "Content-Type: application/json" -H "X-Vault-Token: $root_token" -X PUT -d @roleKubeProxy.json https://127.0.0.1:8200/v1/sys/policy/kube-proxy

curl --cacert /home/vault/ssl/vault1/ca.pem -H "Content-Type: application/json" -H "X-Vault-Token: $root_token" -X POST -d @rolesVault.json https://127.0.0.1:8200/v1/vault/roles/vault
curl --cacert /home/vault/ssl/vault1/ca.pem -H "Content-Type: application/json" -H "X-Vault-Token: $root_token" -X POST -d @rolesEtcd.json https://127.0.0.1:8200/v1/etcd/roles/etcd
curl --cacert /home/vault/ssl/vault1/ca.pem -H "content-type: application/json" -H "x-vault-token: $root_token" -X POST -d @roleskubemaster.json https://127.0.0.1:8200/v1/kube/roles/kube-master
curl --cacert /home/vault/ssl/vault1/ca.pem -H "Content-Type: application/json" -H "X-Vault-Token: $root_token" -X POST -d @rolesKubeNode.json https://127.0.0.1:8200/v1/kube/roles/kube-node
curl --cacert /home/vault/ssl/vault1/ca.pem -H "Content-Type: application/json" -H "X-Vault-Token: $root_token" -X POST -d @rolesKubeProxy.json https://127.0.0.1:8200/v1/kube/roles/kube-proxy

curl --cacert /home/vault/ssl/vault1/ca.pem -H "Content-Type: application/json" -H "X-Vault-Token: $root_token" -X POST -d @auth.json https://127.0.0.1:8200/v1/sys/auth/userpass
curl --cacert /home/vault/ssl/vault1/ca.pem -H "Content-Type: application/json" -H "X-Vault-Token: $root_token" -X POST -d @userEtcd.json https://127.0.0.1:8200/v1/auth/userpass/users/etcd
curl --cacert /home/vault/ssl/vault1/ca.pem -H "Content-Type: application/json" -H "X-Vault-Token: $root_token" -X POST -d @userVault.json https://127.0.0.1:8200/v1/auth/userpass/users/vault
curl --cacert /home/vault/ssl/vault1/ca.pem -H "Content-Type: application/json" -H "X-Vault-Token: $root_token" -X POST -d @userKubeMaster.json https://127.0.0.1:8200/v1/auth/userpass/users/kube-master
curl --cacert /home/vault/ssl/vault1/ca.pem -H "Content-Type: application/json" -H "X-Vault-Token: $root_token" -X POST -d @userKubeNode.json https://127.0.0.1:8200/v1/auth/userpass/users/kube-node
curl --cacert /home/vault/ssl/vault1/ca.pem -H "Content-Type: application/json" -H "X-Vault-Token: $root_token" -X POST -d @userKubeProxy.json https://127.0.0.1:8200/v1/auth/userpass/users/kube-proxy

kubePems=$(curl --cacert /home/vault/ssl/vault2/ca.pem -H "Content-Type: application/json" -H "X-Vault-Token: $root_token" -X POST -d @genCertKube.json https://127.0.0.1:8200/v1/kube/root/generate/exported)
(
mkdir -p /etc/kubernetes/ssl
cd /etc/kubernetes/ssl || exit
echo "$kubePems" | jq -r ."data.certificate" | sed 's/\\n/\n\r/g' > ca.pem
echo "$kubePems" | jq -r ."data.private_key" | sed 's/\\n/\n\r/g' > ca-key.pem
)
