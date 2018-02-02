#!/bin/sh

allkeys=$(curl --cacert /tmp/home/vault/ssl/ca-master-01.pem  -H "Content-Type: application/json" --request POST --data @vault/init.json https://127.0.0.1:8200/v1/sys/init)
key=$(echo "$allkeys" | jq .'keys'[0])
root_token=$(echo "$allkeys" | jq -r .'root_token')
echo $allkeys
echo $root_token
echo $key

curl --cacert /tmp/home/vault/ssl/ca-master-01.pem  -H "Content-Type: application/json" --request POST -d "{ \"key\": $key }" https://127.0.0.1:8200/v1/sys/unseal
curl --cacert /tmp/home/vault/ssl/ca-master-02.pem  -H "Content-Type: application/json" --request POST -d "{ \"key\": $key }" https://172.17.8.52:8200/v1/sys/unseal
curl --cacert /tmp/home/vault/ssl/ca-master-01.pem  -H "Content-Type: application/json" https://127.0.0.1:8200/v1/sys/health
curl --cacert /tmp/home/vault/ssl/ca-master-01.pem  -H "Content-Type: application/json" https://172.17.8.52:8200/v1/sys/health

curl --cacert /tmp/home/vault/ssl/ca-master-01.pem  -H "Content-Type: application/json" -H "X-Vault-Token: $root_token" -X POST -d @vault/mount.json https://127.0.0.1:8200/v1/sys/mounts/vault
curl --cacert /tmp/home/vault/ssl/ca-master-01.pem  -H "Content-Type: application/json" -H "X-Vault-Token: $root_token" -X POST -d @vault/mount.json https://127.0.0.1:8200/v1/sys/mounts/kube
curl --cacert /tmp/home/vault/ssl/ca-master-01.pem  -H "Content-Type: application/json" -H "X-Vault-Token: $root_token" -X POST -d @vault/mount.json https://127.0.0.1:8200/v1/sys/mounts/etcd

curl --cacert /tmp/home/vault/ssl/ca-master-01.pem  -H "Content-Type: application/json" -H "X-Vault-Token: $root_token" -X PUT -d @vault/roleVault.json https://127.0.0.1:8200/v1/sys/policy/vault
curl --cacert /tmp/home/vault/ssl/ca-master-01.pem  -H "Content-Type: application/json" -H "X-Vault-Token: $root_token" -X PUT -d @vault/roleEtcd.json https://127.0.0.1:8200/v1/sys/policy/etcd
curl --cacert /tmp/home/vault/ssl/ca-master-01.pem  -H "Content-Type: application/json" -H "X-Vault-Token: $root_token" -X PUT -d @vault/roleKubeMaster.json https://127.0.0.1:8200/v1/sys/policy/kube-master
curl --cacert /tmp/home/vault/ssl/ca-master-01.pem  -H "Content-Type: application/json" -H "X-Vault-Token: $root_token" -X PUT -d @vault/roleKubeNode.json https://127.0.0.1:8200/v1/sys/policy/kube-node
curl --cacert /tmp/home/vault/ssl/ca-master-01.pem  -H "Content-Type: application/json" -H "X-Vault-Token: $root_token" -X PUT -d @vault/roleKubeProxy.json https://127.0.0.1:8200/v1/sys/policy/kube-proxy

curl --cacert /tmp/home/vault/ssl/ca-master-01.pem  -H "Content-Type: application/json" -H "X-Vault-Token: $root_token" -X POST -d @vault/rolesVault.json https://127.0.0.1:8200/v1/vault/roles/vault
curl --cacert /tmp/home/vault/ssl/ca-master-01.pem  -H "Content-Type: application/json" -H "X-Vault-Token: $root_token" -X POST -d @vault/rolesEtcd.json https://127.0.0.1:8200/v1/etcd/roles/etcd
curl --cacert /tmp/home/vault/ssl/ca-master-01.pem  -H "content-type: application/json" -H "x-vault-token: $root_token" -X POST -d @vault/rolesKubeMaster.json https://127.0.0.1:8200/v1/kube/roles/kube-master
curl --cacert /tmp/home/vault/ssl/ca-master-01.pem  -H "Content-Type: application/json" -H "X-Vault-Token: $root_token" -X POST -d @vault/rolesKubeNode.json https://127.0.0.1:8200/v1/kube/roles/kube-node
curl --cacert /tmp/home/vault/ssl/ca-master-01.pem  -H "Content-Type: application/json" -H "X-Vault-Token: $root_token" -X POST -d @vault/rolesKubeProxy.json https://127.0.0.1:8200/v1/kube/roles/kube-proxy

curl --cacert /tmp/home/vault/ssl/ca-master-01.pem  -H "Content-Type: application/json" -H "X-Vault-Token: $root_token" -X POST -d @vault/auth.json https://127.0.0.1:8200/v1/sys/auth/userpass
curl --cacert /tmp/home/vault/ssl/ca-master-01.pem  -H "Content-Type: application/json" -H "X-Vault-Token: $root_token" -X POST -d @vault/userEtcd.json https://127.0.0.1:8200/v1/auth/userpass/users/etcd
curl --cacert /tmp/home/vault/ssl/ca-master-01.pem  -H "Content-Type: application/json" -H "X-Vault-Token: $root_token" -X POST -d @vault/userVault.json https://127.0.0.1:8200/v1/auth/userpass/users/vault
curl --cacert /tmp/home/vault/ssl/ca-master-01.pem  -H "Content-Type: application/json" -H "X-Vault-Token: $root_token" -X POST -d @vault/userKubeMaster.json https://127.0.0.1:8200/v1/auth/userpass/users/kube-master
curl --cacert /tmp/home/vault/ssl/ca-master-01.pem  -H "Content-Type: application/json" -H "X-Vault-Token: $root_token" -X POST -d @vault/userKubeNode.json https://127.0.0.1:8200/v1/auth/userpass/users/kube-node
curl --cacert /tmp/home/vault/ssl/ca-master-01.pem  -H "Content-Type: application/json" -H "X-Vault-Token: $root_token" -X POST -d @vault/userKubeProxy.json https://127.0.0.1:8200/v1/auth/userpass/users/kube-proxy

CA=$(cat /tmp/home/etcd/ca-key.pem /tmp/home/etcd/ca.pem | awk 'BEGIN {RS=""}{gsub(/\n/,"\\n",$0); print $0}')
(echo "{ "; echo  \ \ \ \""pem_bundle\"": \"$CA\"; echo }) > vault/putCAetcd.json
curl --cacert /tmp/home/vault/ssl/ca-master-01.pem  -H "Content-Type: application/json" -H "X-Vault-Token: $root_token" -X POST -d @vault/putCAetcd.json https://127.0.0.1:8200/v1/etcd/config/ca

kubePems=$(curl --cacert /tmp/home/vault/ssl/ca-master-02.pem  -H "Content-Type: application/json" -H "X-Vault-Token: $root_token" -X POST -d @vault/genCertKube.json https://127.0.0.1:8200/v1/kube/root/generate/exported)
(
mkdir -p /etc/kubernetes/ssl
cd /etc/kubernetes/ssl || exit
echo "$kubePems" | jq -r ."data.certificate" | sed 's/\\n/\n\r/g' > ca.pem
echo "$kubePems" | jq -r ."data.private_key" | sed 's/\\n/\n\r/g' > ca-key.pem
)

cp /etc/kubernetes/ssl/ca.pem certs/
cp /etc/kubernetes/ssl/ca-key.pem certs/
