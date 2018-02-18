#!/bin/bash
shopt -s expand_aliases

source vault/vault-vars.sh
source k8sConfig/k8sConfig-vars.sh

alias CURL='curl --cacert /tmp/home/vault/ssl/ca-${HOSTNAME}.pem  -H "Content-Type: application/json"'
alias CURLT='CURL -H "X-Vault-Token: $root_token"'

mkdir -p /etc/vault/config

allkeys=$(CURL --request POST --data @vault/init.json https://127.0.0.1:8200/v1/sys/init)
key=$(echo "$allkeys" | jq .'keys'[0])
root_token=$(echo "$allkeys" | jq -r .'root_token')
echo "$allkeys"
echo "$root_token"
echo "$key"

CURL --request POST -d "{ \"key\": $key }" https://127.0.0.1:8200/v1/sys/unseal
CURL https://127.0.0.1:8200/v1/sys/health

cp vault/mount.json /etc/vault/config
CURLT -X POST -d @vault/mount.json https://127.0.0.1:8200/v1/sys/mounts/vault
CURLT -X POST -d @vault/mount.json https://127.0.0.1:8200/v1/sys/mounts/kube
CURLT -X POST -d @vault/mount.json https://127.0.0.1:8200/v1/sys/mounts/etcd

cp vault/policyVault.json /etc/vault/config
CURLT -X PUT -d @/etc/vault/config/policyVault.json https://127.0.0.1:8200/v1/sys/policy/vault
cp vault/policyEtcd.json /etc/vault/config
CURLT -X PUT -d @/etc/vault/config/policyEtcd.json https://127.0.0.1:8200/v1/sys/policy/etcd
sed 's/__POLICY__/kube-master/g' vault/policyKube.json > /etc/vault/config/policyKubeMaster.json
CURLT -X PUT -d @/etc/vault/config/policyKubeMaster.json https://127.0.0.1:8200/v1/sys/policy/kube-master
sed 's/__POLICY__/kube-node/g' vault/policyKube.json > /etc/vault/config/policyKubeNode.json
CURLT -X PUT -d @/etc/vault/config/policyKubeNode.json https://127.0.0.1:8200/v1/sys/policy/kube-node
sed 's/__POLICY__/kube-proxy/g' vault/policyKube.json > /etc/vault/config/policyKubeProxy.json
CURLT -X PUT -d @/etc/vault/config/policyKubeProxy.json https://127.0.0.1:8200/v1/sys/policy/kube-proxy

cp vault/roleVault.json /etc/vault/config
CURLT -X POST -d @/etc/vault/config/roleVault.json https://127.0.0.1:8200/v1/vault/roles/vault
cp vault/roleEtcd.json /etc/vault/config
CURLT -X POST -d @/etc/vault/config/roleEtcd.json https://127.0.0.1:8200/v1/etcd/roles/etcd
sed 's/__ORGANIZATION__/system:masters/g' vault/roleKube.json > /etc/vault/config/roleKubeMaster.json
CURLT -X POST -d @/etc/vault/config/roleKubeMaster.json https://127.0.0.1:8200/v1/kube/roles/kube-master
sed 's/__ORGANIZATION__/system:nodes/g' vault/roleKube.json > /etc/vault/config/roleKubeNode.json
CURLT -X POST -d @/etc/vault/config/roleKubeNode.json https://127.0.0.1:8200/v1/kube/roles/kube-node
sed 's/__ORGANIZATION__/system:node-proxier/g' vault/roleKube.json > /etc/vault/config/roleKubeProxy.json
CURLT -X POST -d @/etc/vault/config/roleKubeProxy.json https://127.0.0.1:8200/v1/kube/roles/kube-proxy

cp vault/auth.json /etc/vault/config
CURLT -X POST -d @/etc/vault/config/auth.json https://127.0.0.1:8200/v1/sys/auth/userpass
sed 's/__USERNAME__/etcd/g; s/__PASSWORD__/etcd/g; s/__POLICY__/etcd/g' vault/users.json > /etc/vault/config/userEtcd.json
CURLT -X POST -d @/etc/vault/config/userEtcd.json https://127.0.0.1:8200/v1/auth/userpass/users/etcd
sed 's/__USERNAME__/vault/g; s/__PASSWORD__/vault/g; s/__POLICY__/vault/g' vault/users.json > /etc/vault/config/userVault.json
CURLT -X POST -d @/etc/vault/config/userVault.json https://127.0.0.1:8200/v1/auth/userpass/users/vault
sed 's/__USERNAME__/kube/g; s/__PASSWORD__/kube/g; s/__POLICY__/kube-master/g' vault/users.json > /etc/vault/config/userKubeMaster.json
CURLT -X POST -d @/etc/vault/config/userKubeMaster.json https://127.0.0.1:8200/v1/auth/userpass/users/kube-master
sed 's/__USERNAME__/kube/g; s/__PASSWORD__/kube/g; s/__POLICY__/kube-node/g' vault/users.json > /etc/vault/config/userKubeNode.json
CURLT -X POST -d @/etc/vault/config/userKubeNode.json https://127.0.0.1:8200/v1/auth/userpass/users/kube-node
sed 's/__USERNAME__/kube/g; s/__PASSWORD__/kube/g; s/__POLICY__/kube-proxy/g' vault/users.json > /etc/vault/config/userKubeProxy.json
CURLT -X POST -d @/etc/vault/config/userKubeProxy.json https://127.0.0.1:8200/v1/auth/userpass/users/kube-proxy

CA=$(cat /tmp/home/etcd/ca-key.pem /tmp/home/etcd/ca.pem | awk 'BEGIN {RS=""}{gsub(/\n/,"\\n",$0); print $0}')
(echo "{ "; echo  \ \ \ \""pem_bundle\"": \"$CA\"; echo }) > vault/putCAetcd.json
CURLT -X POST -d @vault/putCAetcd.json https://127.0.0.1:8200/v1/etcd/config/ca

kubePems=$(CURLT -X POST -d @vault/genCertKube.json https://127.0.0.1:8200/v1/kube/root/generate/exported)
(
mkdir certs
cd certs/ || exit
echo "$kubePems" | jq -r ."data.certificate" | sed 's/\\n/\n\r/g' > ca.pem
echo "$kubePems" | jq -r ."data.private_key" | sed 's/\\n/\n\r/g' > ca-key.pem
)
