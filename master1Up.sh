#!/bin/sh

mkdir -p /etc/kubernetes/ssl
chmod +rwx /etc/kubernetes/ssl
groupadd kube-cert
useradd -s /sbin/nologin -r -g kube-cert -M kube
chgrp kube-cert /etc/kubernetes/ssl/
mkdir -p /opt/bin/kubernetes-scripts
mkdir -p /opt/cni/bin
mkdir -p /etc/cni/net.d

token=$(curl --cacert /home/vault/ssl/vault1/ca.pem -H "Content-Type: application/json" -X POST -d "{\"password\": \"kube\"}" https://127.0.0.1:8200/v1/auth/userpass/login/kube-master |  jq -r ."auth.client_token")

kubeAdminPems=$(curl --cacert /home/vault/ssl/vault1/ca.pem -H "Content-Type: application/json" -H "X-Vault-Token: $token" -X POST -d @genCertKubeAdmin.json https://127.0.0.1:8200/v1/kube/issue/kube-master)
echo "$kubeAdminPems" | jq -r ."data.certificate" | sed 's/\\n/\n\r/g' >  /etc/kubernetes/ssl/admin-master-01.pem
echo "$kubeAdminPems" | jq -r ."data.private_key" | sed 's/\\n/\n\r/g' >  /etc/kubernetes/ssl/admin-master-01-key.pem
echo "$kubeAdminPems" | jq -r ."data.serial_number" | sed 's/\\n/\n\r/g' >  /etc/kubernetes/ssl/sn-admin-master01.pem
echo "$kubeAdminPems" | jq -r ."data.issuing_ca" | sed 's/\\n/\n\r/g' >  /etc/kubernetes/ssl/ca-admin-master01.pem
chmod 0640 /etc/kubernetes/ssl/*admin-master-01*
chown kube:kube-cert /etc/kubernetes/ssl/*admin-master-01*

apiserverPems=$(curl --cacert /home/vault/ssl/vault1/ca.pem -H "Content-Type: application/json" -H "X-Vault-Token: $token" -X POST -d @genCertKubeMaster.json https://127.0.0.1:8200/v1/kube/issue/kube-master)
echo "$apiserverPems" | jq -r ."data.certificate" | sed 's/\\n/\n\r/g' > /etc/kubernetes/ssl/apiserver.pem
echo "$apiserverPems" | jq -r ."data.private_key" | sed 's/\\n/\n\r/g' > /etc/kubernetes/ssl/apiserver-key.pem
echo "$apiserverPems" | jq -r ."data.serial_number" | sed 's/\\n/\n\r/g' > /etc/kubernetes/ssl/sn-apiserver.pem
echo "$apiserverPems" | jq -r ."data.issuing_ca" | sed 's/\\n/\n\r/g' > /etc/kubernetes/ssl/ca-apiserver.pem
chmod 0640 /etc/kubernetes/ssl/*apiserver*
chown kube:kube-cert /etc/kubernetes/ssl/*apiserver*

kubeScheduler=$(curl --cacert /home/vault/ssl/vault1/ca.pem -H "Content-Type: application/json" -H "X-Vault-Token: $token" -X POST -d @genCertKubeMaster.json https://127.0.0.1:8200/v1/kube/issue/kube-master)

echo "$kubeScheduler" | jq -r ."data.certificate" | sed 's/\\n/\n\r/g' >  /etc/kubernetes/ssl/kube-scheduler.pem
echo "$kubeScheduler" | jq -r ."data.private_key" | sed 's/\\n/\n\r/g' >  /etc/kubernetes/ssl/kube-scheduler-key.pem
echo "$kubeScheduler" | jq -r ."data.serial_number" | sed 's/\\n/\n\r/g' >  /etc/kubernetes/ssl/sn-kube-scheduler.pem
echo "$kubeScheduler" | jq -r ."data.issuing_ca" | sed 's/\\n/\n\r/g' >  /etc/kubernetes/ssl/ca-kube-scheduler.pem
chmod 0640 /etc/kubernetes/ssl/*kube-scheduler*
chown kube:kube-cert /etc/kubernetes/ssl/*kube-scheduler*

kubeControllerManagerPems=$(curl --cacert /home/vault/ssl/vault1/ca.pem -H "Content-Type: application/json" -H "X-Vault-Token: $token" -X POST -d @genCertKubeMaster.json https://127.0.0.1:8200/v1/kube/issue/kube-master)

echo "$kubeControllerManagerPems" | jq -r ."data.certificate" | sed 's/\\n/\n\r/g' >  /etc/kubernetes/ssl/kube-controller-manager.pem
echo "$kubeControllerManagerPems" | jq -r ."data.private_key" | sed 's/\\n/\n\r/g' >  /etc/kubernetes/ssl/kube-controller-manager-key.pem
echo "$kubeControllerManagerPems" | jq -r ."data.serial_number" | sed 's/\\n/\n\r/g' >  /etc/kubernetes/ssl/sn-kube-controller-manager.pem
echo "$kubeControllerManagerPems" | jq -r ."data.issuing_ca" | sed 's/\\n/\n\r/g' >  /etc/kubernetes/ssl/ca-kube-controller-manager.pem
chmod 0640 /etc/kubernetes/ssl/*kube-controller-manager*
chown kube:kube-cert /etc/kubernetes/ssl/*kube-controller-manager*

token=$(curl --cacert /home/vault/ssl/vault1/ca.pem -H "Content-Type: application/json" -X POST -d "{\"password\": \"kube\"}" https://127.0.0.1:8200/v1/auth/userpass/login/kube-node |  jq -r ."auth.client_token")

kubeNodePems=$(curl --cacert /home/vault/ssl/vault1/ca.pem -H "Content-Type: application/json" -H "X-Vault-Token: $token" -X POST -d @genCertKubeNodeMaster1.json https://127.0.0.1:8200/v1/kube/issue/kube-node)

echo "$kubeNodePems" | jq -r ."data.certificate" | sed 's/\\n/\n\r/g' >  /etc/kubernetes/ssl/kube-node.pem
echo "$kubeNodePems" | jq -r ."data.private_key" | sed 's/\\n/\n\r/g' >  /etc/kubernetes/ssl/kube-node-key.pem
echo "$kubeNodePems" | jq -r ."data.serial_number" | sed 's/\\n/\n\r/g' >  /etc/kubernetes/ssl/sn-kube-node.pem
echo "$kubeNodePems" | jq -r ."data.issuing_ca" | sed 's/\\n/\n\r/g' >  /etc/kubernetes/ssl/ca-kube-node.pem
chmod 0640 /etc/kubernetes/ssl/*kube-node*
chown kube:kube-cert /etc/kubernetes/ssl/*kube-node*

token=$(curl --cacert /home/vault/ssl/vault1/ca.pem -H "Content-Type: application/json" -X POST -d "{\"password\": \"kube\"}" https://127.0.0.1:8200/v1/auth/userpass/login/kube-proxy |  jq -r ."auth.client_token")

kubeProxyPems=$(curl --cacert /home/vault/ssl/vault1/ca.pem -H "Content-Type: application/json" -H "X-Vault-Token: $token" -X POST -d @genCertKubeProxyMaster1.json https://127.0.0.1:8200/v1/kube/issue/kube-proxy)

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

cp kubelet1.env /etc/kubernetes/kubelet.env
cp kubelet.service /etc/systemd/system/kubelet.service
cp kubelet-kubeconfig1.yaml /etc/kubernetes/kubelet-kubeconfig.yaml
systemctl daemon-reload
cp kubelet-container.sh /opt/bin/kubelet
chmod +x /opt/bin/kubelet

sysctl -w net.ipv4.ip_local_reserved_ports="30000-32767"

cp kube-proxy-kubeconfig.yaml /etc/kubernetes/
cp node-kubeconfig.yaml /etc/kubernetes/

mkdir -p /etc/kubernetes/manifests/

cp kube-proxy1.manifest /etc/kubernetes/manifests/kube-proxy.manifest


mkdir -p /etc/kubernetes/users/
chgrp kube-cert /etc/kubernetes/users/
cp known_users.csv /etc/kubernetes/users/

docker run --rm -v /opt/bin:/systembindir quay.io/coreos/hyperkube:v1.9.2_coreos.0 /bin/cp /hyperkube /systembindir/kubectl

cp kube-apiserver1.manifest /etc/kubernetes/manifests/kube-apiserver.manifest

cp kube-scheduler-kubeconfig.yaml /etc/kubernetes/
cp kube-scheduler1.manifest /etc/kubernetes/manifests/kube-scheduler.manifest
cp kube-controller-manager-kubeconfig.yaml /etc/kubernetes/
cp kube-controller-manager1.manifest /etc/kubernetes/manifests/kube-controller-manager.manifest

mkdir -p /root/.kube
chmod 700 /root/.kube
cp admin1.conf /etc/kubernetes/admin.conf
chmod 640 /etc/kubernetes/admin.conf
cp /etc/kubernetes/admin.conf /root/.kube/config
chmod 700 /root/.kube/config

systemctl start kubelet


cp calico-kubeconfig1.yaml /etc/cni/net.d/10-calico.conflist
chown kube:kube-cert /etc/cni/net.d/10-calico.conflist

mkdir -p /etc/calico/certs
chown root:root /etc/calico/certs
chmod 750 /etc/calico/certs

cp /etc/ssl/etcd/ssl/ca.pem /etc/calico/certs/ca_cert.crt
cp /etc/ssl/etcd/ssl/proxy-etcd-01.pem /etc/calico/certs/cert.crt
cp /etc/ssl/etcd/ssl/proxy-etcd-01-key.pem /etc/calico/certs/key.pem
cp calicoctl-container /opt/bin/calicoctl
chmod +x /opt/bin/calicoctl
docker run --rm -v /opt/cni/bin:/cnibindir quay.io/calico/cni:v1.11.0 sh -c 'cp /opt/cni/bin/* /cnibindir/'
chown kube:kube-cert /opt/cni/bin
chmod 755 /opt/cni/bin

echo '{
    "kind": "ipPool",
    "spec": {"disabled": false, "ipip": {"enabled": true, "mode": "always"},
             "nat-outgoing": true},
    "apiVersion": "v1",
    "metadata": {"cidr": "10.233.64.0/18"}
    }' | calicoctl create -f -

curl --cacert /etc/ssl/etcd/ssl/ca.pem https://localhost:2379/v2/keys/calico/v1/ipam/v4/pool | jq -r
calicoctl config set asNumber 64512
calicoctl config set nodeToNodeMesh off

cp calico-config.yml /etc/kubernetes
cp calico-node.yml /etc/kubernetes
cp calico-node-sa.yml /etc/kubernetes
cp calico-cr.yml /etc/kubernetes
cp calico-crb.yml /etc/kubernetes
