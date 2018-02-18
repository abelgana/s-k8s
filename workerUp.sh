#!/bin/bash

mkdir -p /etc/kubernetes/ssl
chmod +rwx /etc/kubernetes/ssl
groupadd kube-cert
useradd -s /sbin/nologin -r -g kube-cert -M kube
chgrp kube-cert /etc/kubernetes/ssl/
mkdir -p /opt/bin/kubernetes-scripts
mkdir -p /opt/cni/bin
mkdir -p /etc/cni/net.d
mkdir -p /etc/ssl/etcd/ssl
mkdir -p /etc/kubernetes/manifests
mkdir -p /etc/vault

cp certs/ca.pem /etc/kubernetes/ssl/

source k8sConfig/k8sConfig-vars.sh

tar -xf certs/vault.tar -C /tmp
token=$(curl --cacert /tmp/home/vault/ssl/ca-master-01.pem  -H "Content-Type: application/json" -X POST -d "{\"password\": \"etcd\"}" https://172.17.8.51:8200/v1/auth/userpass/login/etcd |  jq -r ."auth.client_token")

envsubst < vault/issueCertNode.json > /etc/vault/issueCertNode.json
etcdPems=$(curl --cacert /tmp/home/vault/ssl/ca-master-01.pem  -H "Content-Type: application/json" -H "X-Vault-Token: $token" -X POST -d @/etc/vault/issueCertNode.json https://172.17.8.51:8200/v1/etcd/issue/etcd)
echo "$etcdPems" | jq -r ."data.certificate" | sed 's/\\n/\n\r/g' >  /etc/ssl/etcd/ssl/etcd.pem
echo "$etcdPems" | jq -r ."data.private_key" | sed 's/\\n/\n\r/g' >  /etc/ssl/etcd/ssl/etcd-key.pem
echo "$etcdPems" | jq -r ."data.serial_number" | sed 's/\\n/\n\r/g' >  /etc/ssl/etcd/ssl/sn-etcd-key.pem
echo "$etcdPems" | jq -r ."data.issuing_ca" | sed 's/\\n/\n\r/g' >  /etc/ssl/etcd/ssl/ca-etcd-key.pem
chmod 0640 /etc/ssl/etcd/ssl/etcd.pem
chown kube:kube-cert /etc/ssl/etcd/ssl/*etcd*

token=$(curl --cacert /tmp/home/vault/ssl/ca-master-01.pem  -H "Content-Type: application/json" -X POST -d "{\"password\": \"kube\"}" https://172.17.8.51:8200/v1/auth/userpass/login/kube-node |  jq -r ."auth.client_token")

envsubst < vault/genCertKubeNodeMaster.json > /etc/vault/genCertKubeNodeMaster.json
kubeNodePems=$(curl --cacert /tmp/home/vault/ssl/ca-master-01.pem  -H "Content-Type: application/json" -H "X-Vault-Token: $token" -X POST -d @/etc/vault/genCertKubeNodeMaster.json https://172.17.8.51:8200/v1/kube/issue/kube-node)

echo "$kubeNodePems" | jq -r ."data.certificate" | sed 's/\\n/\n\r/g' >  /etc/kubernetes/ssl/kube-node.pem
echo "$kubeNodePems" | jq -r ."data.private_key" | sed 's/\\n/\n\r/g' >  /etc/kubernetes/ssl/kube-node-key.pem
echo "$kubeNodePems" | jq -r ."data.serial_number" | sed 's/\\n/\n\r/g' >  /etc/kubernetes/ssl/sn-kube-node.pem
echo "$kubeNodePems" | jq -r ."data.issuing_ca" | sed 's/\\n/\n\r/g' >  /etc/kubernetes/ssl/ca-kube-node.pem
chmod 0640 /etc/kubernetes/ssl/*kube-node*
chown kube:kube-cert /etc/kubernetes/ssl/*kube-node*

token=$(curl --cacert /tmp/home/vault/ssl/ca-master-01.pem  -H "Content-Type: application/json" -X POST -d "{\"password\": \"kube\"}" https://172.17.8.51:8200/v1/auth/userpass/login/kube-proxy |  jq -r ."auth.client_token")

kubeProxyPems=$(curl --cacert /tmp/home/vault/ssl/ca-master-01.pem  -H "Content-Type: application/json" -H "X-Vault-Token: $token" -X POST -d @vault/genCertKubeProxyMaster.json https://172.17.8.51:8200/v1/kube/issue/kube-proxy)

echo "$kubeProxyPems" | jq -r ."data.certificate" | sed 's/\\n/\n\r/g' >  /etc/kubernetes/ssl/kube-proxy.pem
echo "$kubeProxyPems" | jq -r ."data.private_key" | sed 's/\\n/\n\r/g' >  /etc/kubernetes/ssl/kube-proxy-key.pem
echo "$kubeProxyPems" | jq -r ."data.serial_number" | sed 's/\\n/\n\r/g' >  /etc/kubernetes/ssl/sn-kube-proxy.pem
echo "$kubeProxyPems" | jq -r ."data.issuing_ca" | sed 's/\\n/\n\r/g' >  /etc/kubernetes/ssl/ca-kube-proxy.pem
chmod 0640 /etc/kubernetes/ssl/*kube-proxy*
chown kube:kube-cert /etc/kubernetes/ssl/*kube-proxy*


cp /etc/kubernetes/ssl/ca.pem /etc/ssl/certs/kube-ca.pem
update-ca-certificate > /dev/null

mkdir -p /var/lib/cni
chmod 0755 /var/lib/cni

cp k8sConfig/kube-proxy-kubeconfig.yaml /etc/kubernetes/
envsubst < k8sManifest/kube-proxy.manifest > /etc/kubernetes/manifests/kube-proxy.manifest

envsubst < kubelet/kubelet-worker.env > /etc/kubernetes/kubelet.env
cp kubelet/kubelet.service /etc/systemd/system/kubelet.service
cp kubelet/kubelet-kubeconfig.yaml /etc/kubernetes/kubelet-kubeconfig.yaml
envsubst < kubelet/kubelet-container.sh > /opt/bin/kubelet
chmod +x /opt/bin/kubelet
systemctl daemon-reload
systemctl start kubelet
