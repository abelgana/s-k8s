#!/bin/bash

function vault::create_needed_folders() {
    echo "Creating required folders for vault"
    mkdir -p /etc/vault/ssl
    mkdir -p /etc/vault/config
    mkdir -p /etc/vault/secrets
    mkdir -p /var/log/vault
    mkdir -p /var/lib/vault
    mkdir -p /etc/ssl/etcd/ssl/
    mkdir -p certs
    id -u vault &>/dev/null || useradd -U -m vault -G sudo
    chown -R vault /etc/vault/
    chown -R vault /var/log/vault
    chown -R vault /var/lib/vault
}

function vault::copy_ssl_certificates() {
    echo "Copying required ssl certificates for vault"
    tar -xf certs/vault.tar -C /tmp
    cp /tmp/home/vault/ssl/api-${HOSTNAME}.pem /etc/vault/ssl/api.pem
    cp /tmp/home/vault/ssl/api-${HOSTNAME}-key.pem /etc/vault/ssl/api-key.pem
    cp /tmp/home/vault/ssl/api-${HOSTNAME}.pem /etc/vault/ssl/aca.pem
}

function vault::configure_vault() {
    echo "Configuring vault"
    cp vault/vaultConfig.json /etc/vault/config/config.json
    envsubst < vault/vaultConfig.json > /etc/vault/config/config.json
    cp vault/vault.service /etc/systemd/system/vault.service
}

function vault:start_vault() {
    echo "Starting vault"
    systemctl enable namerd.service > /dev/null 2>&1
    systemctl daemon-reload
    systemctl start vault.service
    vault::curl https://127.0.0.1:8200/v1/sys/health > /dev/null
    echo "Vault is started"
}

function vault::curl() {
   curl --silent --retry-connrefused --connect-timeout 5 --retry 5 --retry-delay 0 --retry-max-time 40 --cacert /tmp/home/vault/ssl/ca-${HOSTNAME}.pem  -H "Content-Type: application/json" "$@"
}

function vault::curlt() {
    curl --silent --retry-connrefused --connect-timeout 5 --retry 5 --retry-delay 0 --retry-max-time 40 --cacert /tmp/home/vault/ssl/ca-${HOSTNAME}.pem  -H "Content-Type: application/json" -H "X-Vault-Token: $root_token" "$@"
}

function vault::vault_create_mounts() {
    cp vault/mount.json /etc/vault/config
    vault::curlt -X POST -d @vault/mount.json https://127.0.0.1:8200/v1/sys/mounts/vault
    vault::curlt -X POST -d @vault/mount.json https://127.0.0.1:8200/v1/sys/mounts/kube
    vault::curlt -X POST -d @vault/mount.json https://127.0.0.1:8200/v1/sys/mounts/etcd
}

function vault::configure_policies() {
    cp vault/policyVault.json /etc/vault/config
    vault::curlt -X PUT -d @/etc/vault/config/policyVault.json https://127.0.0.1:8200/v1/sys/policy/vault
    cp vault/policyEtcd.json /etc/vault/config
    vault::curlt -X PUT -d @/etc/vault/config/policyEtcd.json https://127.0.0.1:8200/v1/sys/policy/etcd
    sed 's/__POLICY__/kube-master/g' vault/policyKube.json > /etc/vault/config/policyKubeMaster.json
    vault::curlt -X PUT -d @/etc/vault/config/policyKubeMaster.json https://127.0.0.1:8200/v1/sys/policy/kube-master
    sed 's/__POLICY__/kube-node/g' vault/policyKube.json > /etc/vault/config/policyKubeNode.json
    vault::curlt -X PUT -d @/etc/vault/config/policyKubeNode.json https://127.0.0.1:8200/v1/sys/policy/kube-node
    sed 's/__POLICY__/kube-proxy/g' vault/policyKube.json > /etc/vault/config/policyKubeProxy.json
    vault::curlt -X PUT -d @/etc/vault/config/policyKubeProxy.json https://127.0.0.1:8200/v1/sys/policy/kube-proxy
}

function vault::configure_roles() {
    cp vault/roleVault.json /etc/vault/config
    vault::curlt -X POST -d @/etc/vault/config/roleVault.json https://127.0.0.1:8200/v1/vault/roles/vault
    cp vault/roleEtcd.json /etc/vault/config
    vault::curlt -X POST -d @/etc/vault/config/roleEtcd.json https://127.0.0.1:8200/v1/etcd/roles/etcd
    sed 's/__ORGANIZATION__/system:masters/g' vault/roleKube.json > /etc/vault/config/roleKubeMaster.json
    vault::curlt -X POST -d @/etc/vault/config/roleKubeMaster.json https://127.0.0.1:8200/v1/kube/roles/kube-master
    sed 's/__ORGANIZATION__/system:nodes/g' vault/roleKube.json > /etc/vault/config/roleKubeNode.json
    vault::curlt -X POST -d @/etc/vault/config/roleKubeNode.json https://127.0.0.1:8200/v1/kube/roles/kube-node
    sed 's/__ORGANIZATION__/system:node-proxier/g' vault/roleKube.json > /etc/vault/config/roleKubeProxy.json
    vault::curlt -X POST -d @/etc/vault/config/roleKubeProxy.json https://127.0.0.1:8200/v1/kube/roles/kube-proxy
}

function vault::configure_users() {
    cp vault/auth.json /etc/vault/config
    vault::curlt -X POST -d @/etc/vault/config/auth.json https://127.0.0.1:8200/v1/sys/auth/userpass
    sed 's/__USERNAME__/etcd/g; s/__PASSWORD__/etcd/g; s/__POLICY__/etcd/g' vault/users.json > /etc/vault/config/userEtcd.json
    vault::curlt -X POST -d @/etc/vault/config/userEtcd.json https://127.0.0.1:8200/v1/auth/userpass/users/etcd
    sed 's/__USERNAME__/vault/g; s/__PASSWORD__/vault/g; s/__POLICY__/vault/g' vault/users.json > /etc/vault/config/userVault.json
    vault::curlt -X POST -d @/etc/vault/config/userVault.json https://127.0.0.1:8200/v1/auth/userpass/users/vault
    sed 's/__USERNAME__/kube/g; s/__PASSWORD__/kube/g; s/__POLICY__/kube-master/g' vault/users.json > /etc/vault/config/userKubeMaster.json
    vault::curlt -X POST -d @/etc/vault/config/userKubeMaster.json https://127.0.0.1:8200/v1/auth/userpass/users/kube-master
    sed 's/__USERNAME__/kube/g; s/__PASSWORD__/kube/g; s/__POLICY__/kube-node/g' vault/users.json > /etc/vault/config/userKubeNode.json
    vault::curlt -X POST -d @/etc/vault/config/userKubeNode.json https://127.0.0.1:8200/v1/auth/userpass/users/kube-node
    sed 's/__USERNAME__/kube/g; s/__PASSWORD__/kube/g; s/__POLICY__/kube-proxy/g' vault/users.json > /etc/vault/config/userKubeProxy.json
    vault::curlt -X POST -d @/etc/vault/config/userKubeProxy.json https://127.0.0.1:8200/v1/auth/userpass/users/kube-proxy
}

function vault::add_etcd_certificates() {
    CA=$(cat /tmp/home/etcd/ca-key.pem /tmp/home/etcd/ca.pem | awk 'BEGIN {RS=""}{gsub(/\n/,"\\n",$0); print $0}')
    (echo "{ "; echo  \ \ \ \""pem_bundle\"": \"$CA\"; echo }) > vault/putCAetcd.json
    vault::curlt -X POST -d @vault/putCAetcd.json https://127.0.0.1:8200/v1/etcd/config/ca
}

function vault::create_ca_cert_for_kubernetes() {
    kubePems=$(vault::curlt -X POST -d @vault/genCertKube.json https://127.0.0.1:8200/v1/kube/root/generate/exported)
    echo "$kubePems" | jq -r ."data.certificate" | sed 's/\\n/\n\r/g' > certs/ca.pem
    echo "$kubePems" | jq -r ."data.private_key" | sed 's/\\n/\n\r/g' > certs/ca-key.pem
}

function vault::initialize_vault() {
    echo "Initilizing vault"
    allkeys=$(vault::curl --request POST --data @vault/init.json https://127.0.0.1:8200/v1/sys/init) > /dev/null 2>&1
    key=$(echo "$allkeys" | jq .'keys'[0])
    root_token=$(echo "$allkeys" | jq -r .'root_token')
    echo "$allkeys" > certs/allkeys
    echo "$root_token" > certs/root_token
    echo "$key" > certs/key

    vault::curl --request POST -d "{ \"key\": $key }" https://127.0.0.1:8200/v1/sys/unseal > /dev/null 2>&1
    vault::curl https://127.0.0.1:8200/v1/sys/health
    vault::vault_create_mounts
    vault::configure_policies
    vault::configure_roles
    vault::configure_users
    vault::add_etcd_certificates
    vault::create_ca_cert_for_kubernetes
}
