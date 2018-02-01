#!/bin/sh

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

cp certs/ca.pem /etc/kubernetes/ssl/

tar -xf certs/vault.tar -C /tmp
token=$(curl --cacert /tmp/home/vault/ssl/vault1/ca.pem -H "Content-Type: application/json" -X POST -d "{\"password\": \"etcd\"}" https://172.17.8.51:8200/v1/auth/userpass/login/etcd |  jq -r ."auth.client_token")

etcdPems=$(curl --cacert /tmp/home/vault/ssl/vault1/ca.pem -H "Content-Type: application/json" -H "X-Vault-Token: $token" -X POST -d @vault/issueCertMaster1.json https://172.17.8.51:8200/v1/etcd/issue/etcd)
echo "$etcdPems" | jq -r ."data.certificate" | sed 's/\\n/\n\r/g' >  /etc/ssl/etcd/ssl/etcd.pem
echo "$etcdPems" | jq -r ."data.private_key" | sed 's/\\n/\n\r/g' >  /etc/ssl/etcd/ssl/etcd-key.pem
echo "$etcdPems" | jq -r ."data.serial_number" | sed 's/\\n/\n\r/g' >  /etc/ssl/etcd/ssl/sn-etcd-key.pem
echo "$etcdPems" | jq -r ."data.issuing_ca" | sed 's/\\n/\n\r/g' >  /etc/ssl/etcd/ssl/ca-etcd-key.pem
chmod 0640 /etc/ssl/etcd/ssl/etcd.pem
chown kube:kube-cert /etc/ssl/etcd/ssl/*etcd*

token=$(curl --cacert /tmp/home/vault/ssl/vault1/ca.pem -H "Content-Type: application/json" -X POST -d "{\"password\": \"kube\"}" https://172.17.8.51:8200/v1/auth/userpass/login/kube-node |  jq -r ."auth.client_token")

kubeNodePems=$(curl --cacert /tmp/home/vault/ssl/vault1/ca.pem -H "Content-Type: application/json" -H "X-Vault-Token: $token" -X POST -d @vault/genCertKubeNodeMaster1.json https://172.17.8.51:8200/v1/kube/issue/kube-node)

echo "$kubeNodePems" | jq -r ."data.certificate" | sed 's/\\n/\n\r/g' >  /etc/kubernetes/ssl/kube-node.pem
echo "$kubeNodePems" | jq -r ."data.private_key" | sed 's/\\n/\n\r/g' >  /etc/kubernetes/ssl/kube-node-key.pem
echo "$kubeNodePems" | jq -r ."data.serial_number" | sed 's/\\n/\n\r/g' >  /etc/kubernetes/ssl/sn-kube-node.pem
echo "$kubeNodePems" | jq -r ."data.issuing_ca" | sed 's/\\n/\n\r/g' >  /etc/kubernetes/ssl/ca-kube-node.pem
chmod 0640 /etc/kubernetes/ssl/*kube-node*
chown kube:kube-cert /etc/kubernetes/ssl/*kube-node*

token=$(curl --cacert /tmp/home/vault/ssl/vault1/ca.pem -H "Content-Type: application/json" -X POST -d "{\"password\": \"kube\"}" https://172.17.8.51:8200/v1/auth/userpass/login/kube-proxy |  jq -r ."auth.client_token")

kubeProxyPems=$(curl --cacert /tmp/home/vault/ssl/vault1/ca.pem -H "Content-Type: application/json" -H "X-Vault-Token: $token" -X POST -d @vault/genCertKubeProxyMaster1.json https://172.17.8.51:8200/v1/kube/issue/kube-proxy)

echo "$kubeProxyPems" | jq -r ."data.certificate" | sed 's/\\n/\n\r/g' >  /etc/kubernetes/ssl/kube-proxy.pem
echo "$kubeProxyPems" | jq -r ."data.private_key" | sed 's/\\n/\n\r/g' >  /etc/kubernetes/ssl/kube-proxy-key.pem
echo "$kubeProxyPems" | jq -r ."data.serial_number" | sed 's/\\n/\n\r/g' >  /etc/kubernetes/ssl/sn-kube-proxy.pem
echo "$kubeProxyPems" | jq -r ."data.issuing_ca" | sed 's/\\n/\n\r/g' >  /etc/kubernetes/ssl/update-ca-certificatesca-kube-proxy.pem
chmod 0640 /etc/kubernetes/ssl/*kube-proxy*
chown kube:kube-cert /etc/kubernetes/ssl/*kube-proxy*


cp /etc/kubernetes/ssl/ca.pem /etc/ssl/certs/kube-ca.pem
update-ca-certificates

mkdir -p /var/lib/cni
chmod 0755 /var/lib/cni

cp kubelet/kubelet.env /etc/kubernetes/kubelet.env
cp kubelet/kubelet.service /etc/systemd/system/kubelet.service
cp kubelet/kubelet-kubeconfig.yaml /etc/kubernetes/kubelet-kubeconfig.yaml
cp kubelet/kubelet-container.sh /opt/bin/kubelet
chmod +x /opt/bin/kubelet
systemctl daemon-reload
systemctl start kubelet

mkdir -p /etc/nginx
cp nginx/nginx.conf /etc/nginx
cp nginx/nginx.manifest /etc/kubernetes/manifests/
