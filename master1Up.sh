#!/bin/sh

mkdir -p /etc/kubernetes/ssl
chmod +rwx /etc/kubernetes/ssl
groupadd kube-cert
useradd -s /sbin/nologin -r -g kube-cert -M kube
chgrp kube-cert /etc/kubernetes/ssl/
mkdir -p /opt/bin/kubernetes-scripts
mkdir -p /opt/cni/bin
mkdir -p /etc/cni/net.d

token=$(curl --cacert /tmp/home/vault/ssl/ca-master-01.pem  -H "Content-Type: application/json" -X POST -d "{\"password\": \"etcd\"}" https://127.0.0.1:8200/v1/auth/userpass/login/etcd |  jq -r ."auth.client_token")

etcdPems=$(curl --cacert /tmp/home/vault/ssl/ca-master-01.pem  -H "Content-Type: application/json" -H "X-Vault-Token: $token" -X POST -d @vault/issueCertMaster1.json https://127.0.0.1:8200/v1/etcd/issue/etcd)
echo "$etcdPems" | jq -r ."data.certificate" | sed 's/\\n/\n\r/g' >  /etc/ssl/etcd/ssl/etcd.pem
echo "$etcdPems" | jq -r ."data.private_key" | sed 's/\\n/\n\r/g' >  /etc/ssl/etcd/ssl/etcd-key.pem
echo "$etcdPems" | jq -r ."data.serial_number" | sed 's/\\n/\n\r/g' >  /etc/ssl/etcd/ssl/sn-etcd-key.pem
echo "$etcdPems" | jq -r ."data.issuing_ca" | sed 's/\\n/\n\r/g' >  /etc/ssl/etcd/ssl/ca-etcd-key.pem
chmod 0640 /etc/ssl/etcd/ssl/etcd.pem
chown kube:kube-cert /etc/ssl/etcd/ssl/*etcd*

token=$(curl --cacert /tmp/home/vault/ssl/ca-master-01.pem  -H "Content-Type: application/json" -X POST -d "{\"password\": \"kube\"}" https://127.0.0.1:8200/v1/auth/userpass/login/kube-master |  jq -r ."auth.client_token")

kubeAdminPems=$(curl --cacert /tmp/home/vault/ssl/ca-master-01.pem  -H "Content-Type: application/json" -H "X-Vault-Token: $token" -X POST -d @vault/genCertKubeAdmin.json https://127.0.0.1:8200/v1/kube/issue/kube-master)
echo "$kubeAdminPems" | jq -r ."data.certificate" | sed 's/\\n/\n\r/g' >  /etc/kubernetes/ssl/admin-master-01.pem
echo "$kubeAdminPems" | jq -r ."data.private_key" | sed 's/\\n/\n\r/g' >  /etc/kubernetes/ssl/admin-master-01-key.pem
echo "$kubeAdminPems" | jq -r ."data.serial_number" | sed 's/\\n/\n\r/g' >  /etc/kubernetes/ssl/sn-admin-master01.pem
echo "$kubeAdminPems" | jq -r ."data.issuing_ca" | sed 's/\\n/\n\r/g' >  /etc/kubernetes/ssl/ca-admin-master01.pem
chmod 0640 /etc/kubernetes/ssl/*admin-master-01*
chown kube:kube-cert /etc/kubernetes/ssl/*admin-master-01*

apiserverPems=$(curl --cacert /tmp/home/vault/ssl/ca-master-01.pem  -H "Content-Type: application/json" -H "X-Vault-Token: $token" -X POST -d @vault/genCertKubeMaster.json https://127.0.0.1:8200/v1/kube/issue/kube-master)
echo "$apiserverPems" | jq -r ."data.certificate" | sed 's/\\n/\n\r/g' > /etc/kubernetes/ssl/apiserver.pem
echo "$apiserverPems" | jq -r ."data.private_key" | sed 's/\\n/\n\r/g' > /etc/kubernetes/ssl/apiserver-key.pem
echo "$apiserverPems" | jq -r ."data.serial_number" | sed 's/\\n/\n\r/g' > /etc/kubernetes/ssl/sn-apiserver.pem
echo "$apiserverPems" | jq -r ."data.issuing_ca" | sed 's/\\n/\n\r/g' > /etc/kubernetes/ssl/ca-apiserver.pem
chmod 0640 /etc/kubernetes/ssl/*apiserver*
chown kube:kube-cert /etc/kubernetes/ssl/*apiserver*

kubeScheduler=$(curl --cacert /tmp/home/vault/ssl/ca-master-01.pem  -H "Content-Type: application/json" -H "X-Vault-Token: $token" -X POST -d @vault/genCertKubeMaster.json https://127.0.0.1:8200/v1/kube/issue/kube-master)

echo "$kubeScheduler" | jq -r ."data.certificate" | sed 's/\\n/\n\r/g' >  /etc/kubernetes/ssl/kube-scheduler.pem
echo "$kubeScheduler" | jq -r ."data.private_key" | sed 's/\\n/\n\r/g' >  /etc/kubernetes/ssl/kube-scheduler-key.pem
echo "$kubeScheduler" | jq -r ."data.serial_number" | sed 's/\\n/\n\r/g' >  /etc/kubernetes/ssl/sn-kube-scheduler.pem
echo "$kubeScheduler" | jq -r ."data.issuing_ca" | sed 's/\\n/\n\r/g' >  /etc/kubernetes/ssl/ca-kube-scheduler.pem
chmod 0640 /etc/kubernetes/ssl/*kube-scheduler*
chown kube:kube-cert /etc/kubernetes/ssl/*kube-scheduler*

kubeControllerManagerPems=$(curl --cacert /tmp/home/vault/ssl/ca-master-01.pem  -H "Content-Type: application/json" -H "X-Vault-Token: $token" -X POST -d @vault/genCertKubeMaster.json https://127.0.0.1:8200/v1/kube/issue/kube-master)

echo "$kubeControllerManagerPems" | jq -r ."data.certificate" | sed 's/\\n/\n\r/g' >  /etc/kubernetes/ssl/kube-controller-manager.pem
echo "$kubeControllerManagerPems" | jq -r ."data.private_key" | sed 's/\\n/\n\r/g' >  /etc/kubernetes/ssl/kube-controller-manager-key.pem
echo "$kubeControllerManagerPems" | jq -r ."data.serial_number" | sed 's/\\n/\n\r/g' >  /etc/kubernetes/ssl/sn-kube-controller-manager.pem
echo "$kubeControllerManagerPems" | jq -r ."data.issuing_ca" | sed 's/\\n/\n\r/g' >  /etc/kubernetes/ssl/ca-kube-controller-manager.pem
chmod 0640 /etc/kubernetes/ssl/*kube-controller-manager*
chown kube:kube-cert /etc/kubernetes/ssl/*kube-controller-manager*

token=$(curl --cacert /tmp/home/vault/ssl/ca-master-01.pem  -H "Content-Type: application/json" -X POST -d "{\"password\": \"kube\"}" https://127.0.0.1:8200/v1/auth/userpass/login/kube-node |  jq -r ."auth.client_token")

kubeNodePems=$(curl --cacert /tmp/home/vault/ssl/ca-master-01.pem  -H "Content-Type: application/json" -H "X-Vault-Token: $token" -X POST -d @vault/genCertKubeNodeMaster1.json https://127.0.0.1:8200/v1/kube/issue/kube-node)

echo "$kubeNodePems" | jq -r ."data.certificate" | sed 's/\\n/\n\r/g' >  /etc/kubernetes/ssl/kube-node.pem
echo "$kubeNodePems" | jq -r ."data.private_key" | sed 's/\\n/\n\r/g' >  /etc/kubernetes/ssl/kube-node-key.pem
echo "$kubeNodePems" | jq -r ."data.serial_number" | sed 's/\\n/\n\r/g' >  /etc/kubernetes/ssl/sn-kube-node.pem
echo "$kubeNodePems" | jq -r ."data.issuing_ca" | sed 's/\\n/\n\r/g' >  /etc/kubernetes/ssl/ca-kube-node.pem
chmod 0640 /etc/kubernetes/ssl/*kube-node*
chown kube:kube-cert /etc/kubernetes/ssl/*kube-node*

token=$(curl --cacert /tmp/home/vault/ssl/ca-master-01.pem  -H "Content-Type: application/json" -X POST -d "{\"password\": \"kube\"}" https://127.0.0.1:8200/v1/auth/userpass/login/kube-proxy |  jq -r ."auth.client_token")

kubeProxyPems=$(curl --cacert /tmp/home/vault/ssl/ca-master-01.pem  -H "Content-Type: application/json" -H "X-Vault-Token: $token" -X POST -d @vault/genCertKubeProxyMaster.json https://127.0.0.1:8200/v1/kube/issue/kube-proxy)

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
systemctl daemon-reload
cp kubelet/kubelet-container.sh /opt/bin/kubelet
chmod +x /opt/bin/kubelet

sysctl -w net.ipv4.ip_local_reserved_ports="30000-32767"

cp k8sConfig/kube-proxy-kubeconfig.yaml /etc/kubernetes/
cp k8sConfig/node-kubeconfig.yaml /etc/kubernetes/

mkdir -p /etc/kubernetes/manifests/

cp k8sManifest/kube-proxy1.manifest /etc/kubernetes/manifests/kube-proxy.manifest


mkdir -p /etc/kubernetes/users/
chgrp kube-cert /etc/kubernetes/users/
cp k8sConfig/known_users.csv /etc/kubernetes/users/

docker run --rm -v /opt/bin:/systembindir quay.io/coreos/hyperkube:v1.9.2_coreos.0 /bin/cp /hyperkube /systembindir/kubectl

cp k8sManifest/kube-apiserver1.manifest /etc/kubernetes/manifests/kube-apiserver.manifest

cp k8sConfig/kube-scheduler-kubeconfig.yaml /etc/kubernetes/
cp k8sManifest/kube-scheduler1.manifest /etc/kubernetes/manifests/kube-scheduler.manifest
cp k8sConfig/kube-controller-manager-kubeconfig.yaml /etc/kubernetes/
cp k8sManifest/kube-controller-manager1.manifest /etc/kubernetes/manifests/kube-controller-manager.manifest

mkdir -p /root/.kube
chmod 700 /root/.kube
cp k8sConfig/admin1.conf /etc/kubernetes/admin.conf
chmod 640 /etc/kubernetes/admin.conf
cp /etc/kubernetes/admin.conf /root/.kube/config
chmod 700 /root/.kube/config

systemctl start kubelet
