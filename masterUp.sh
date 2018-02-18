#!/bin/bash
shopt -s expand_aliases

mkdir -p /etc/kubernetes/ssl
chmod +rwx /etc/kubernetes/ssl
groupadd kube-cert
useradd -s /sbin/nologin -r -g kube-cert -M kube
chgrp kube-cert /etc/kubernetes/ssl/
mkdir -p /opt/bin/kubernetes-scripts
mkdir -p /opt/cni/bin
mkdir -p /etc/cni/net.d
mkdir -p /etc/vault/config

cp certs/ca.pem /etc/kubernetes/ssl/
cp certs/ca-key.pem /etc/kubernetes/ssl/

source k8sConfig/k8sConfig-vars.sh


alias CURL='curl --cacert /tmp/home/vault/ssl/ca-${HOSTNAME}.pem  -H "Content-Type: application/json"'
alias CURLT='CURL -H "X-Vault-Token: $token"'

gen_cert(){
    token=$(CURL -X POST -d "{\"password\": \"kube\"}" https://127.0.0.1:8200/v1/auth/userpass/login/$2 |  jq -r ."auth.client_token")
    CERT=$(CURLT -X POST -d @/etc/vault/config/"$1".json https://127.0.0.1:8200/v1/kube/issue/"$2")
    echo "$CERT" | jq -r ."data.certificate" | sed 's/\\n/\n\r/g' >  /etc/kubernetes/ssl/"$3".pem
    echo "$CERT" | jq -r ."data.private_key" | sed 's/\\n/\n\r/g' >  /etc/kubernetes/ssl/"$3"-key.pem
    echo "$CERT" | jq -r ."data.serial_number" | sed 's/\\n/\n\r/g' >  /etc/kubernetes/ssl/sn-"$3".pem
    echo "$CERT" | jq -r ."data.issuing_ca" | sed 's/\\n/\n\r/g' >  /etc/kubernetes/ssl/ca-"$3".pem
}

envsubst < vault/issueCertNode.json > /etc/vault/config/issueCertNode.json
token=$(CURL -X POST -d "{\"password\": \"etcd\"}" https://127.0.0.1:8200/v1/auth/userpass/login/etcd |  jq -r ."auth.client_token")
CERT=$(CURLT -X POST -d @/etc/vault/config/issueCertNode.json https://127.0.0.1:8200/v1/etcd/issue/etcd)
echo "$CERT" | jq -r ."data.certificate" | sed 's/\\n/\n\r/g' >  /etc/ssl/etcd/ssl/etcd.pem
echo "$CERT" | jq -r ."data.private_key" | sed 's/\\n/\n\r/g' >  /etc/ssl/etcd/ssl/etcd-key.pem
echo "$CERT" | jq -r ."data.serial_number" | sed 's/\\n/\n\r/g' >  /etc/ssl/etcd/ssl/sn-etcd-key.pem
echo "$CERT" | jq -r ."data.issuing_ca" | sed 's/\\n/\n\r/g' >  /etc/ssl/etcd/ssl/ca-etcd-key.pem
chmod 0640 /etc/ssl/etcd/ssl/etcd.pem
chown kube:kube-cert /etc/ssl/etcd/ssl/*etcd*

cp vault/genCertKubeAdmin.json /etc/vault/config/
gen_cert genCertKubeAdmin kube-master admin

cp vault/genCertKubeMaster.json /etc/vault/config/
gen_cert genCertKubeMaster kube-master apiserver
gen_cert genCertKubeMaster kube-master kube-scheduler
gen_cert genCertKubeMaster kube-master kube-controller-manager

envsubst < vault/genCertKubeNodeMaster.json > /etc/vault/config/genCertKubeNodeMaster.json
gen_cert genCertKubeNodeMaster kube-node kube-node

cp vault/genCertKubeProxyMaster.json /etc/vault/config
gen_cert genCertKubeProxyMaster kube-proxy kube-proxy

chmod 0640 /etc/kubernetes/ssl/*
chown kube:kube-cert /etc/kubernetes/ssl/*

cp /etc/kubernetes/ssl/ca.pem /etc/ssl/certs/kube-ca.pem
update-ca-certificates

mkdir -p /var/lib/cni
chmod 0755 /var/lib/cni

cp kubelet/kubelet.env /etc/kubernetes/kubelet.env
cp kubelet/kubelet.service /etc/systemd/system/kubelet.service
cp kubelet/kubelet-kubeconfig.yaml /etc/kubernetes/kubelet-kubeconfig.yaml
systemctl daemon-reload
envsubst < kubelet/kubelet-container.sh > /opt/bin/kubelet
chmod +x /opt/bin/kubelet

sysctl -w net.ipv4.ip_local_reserved_ports="30000-32767"

cp k8sConfig/kube-proxy-kubeconfig.yaml /etc/kubernetes/

mkdir -p /etc/kubernetes/manifests/

envsubst < k8sManifest/kube-proxy.manifest > /etc/kubernetes/manifests/kube-proxy.manifest

mkdir -p /etc/kubernetes/users/
chgrp kube-cert /etc/kubernetes/users/
cp k8sConfig/known_users.csv /etc/kubernetes/users/

docker run --rm -v /opt/bin:/systembindir quay.io/coreos/hyperkube:v1.9.2_coreos.0 /bin/cp /hyperkube /systembindir/kubectl

envsubst < k8sManifest/kube-apiserver.manifest > /etc/kubernetes/manifests/kube-apiserver.manifest

cp k8sConfig/kube-scheduler-kubeconfig.yaml /etc/kubernetes/
envsubst <  k8sManifest/kube-scheduler.manifest > /etc/kubernetes/manifests/kube-scheduler.manifest
cp k8sConfig/kube-controller-manager-kubeconfig.yaml /etc/kubernetes/
envsubst <  k8sManifest/kube-controller-manager.manifest > /etc/kubernetes/manifests/kube-controller-manager.manifest

mkdir -p /root/.kube
chmod 700 /root/.kube
envsubst < k8sConfig/admin.conf > /etc/kubernetes/admin.conf
chmod 640 /etc/kubernetes/admin.conf
cp /etc/kubernetes/admin.conf /root/.kube/config
chmod 700 /root/.kube/config

systemctl start kubelet
