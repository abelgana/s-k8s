#!/bin/bash

function kube::create_needed_folders() {
    echo "Creating required folders for kubernetes"
    mkdir -p /etc/kubernetes/ssl
    chmod +rwx /etc/kubernetes/ssl
    groupadd kube-cert
    useradd -s /sbin/nologin -r -g kube-cert -M kube
    chgrp kube-cert /etc/kubernetes/ssl/
    mkdir -p /opt/bin/kubernetes-scripts
    mkdir -p /opt/cni/bin
    mkdir -p /etc/cni/net.d
    mkdir -p /etc/vault/config
    mkdir -p /etc/ssl/etcd/ssl

    mkdir -p /var/lib/cni
    chmod 0755 /var/lib/cni

    mkdir -p /etc/kubernetes/users/
    chgrp kube-cert /etc/kubernetes/users/

    mkdir -p /etc/kubernetes/manifests/
    if [ "$1" == 'master' ]
    then
        mkdir -p /root/.kube
        chmod 700 /root/.kube
    fi
}

function kube::curl() {
   curl --silent --retry-connrefused --connect-timeout 5 --retry 5 --retry-delay 0 --retry-max-time 40 --cacert /tmp/home/vault/ca.pem  -H "Content-Type: application/json" "$@"
}

function kube::curlt() {
    curl --silent --retry-connrefused --connect-timeout 5 --retry 5 --retry-delay 0 --retry-max-time 40 --cacert /tmp/home/vault/ca.pem  -H "Content-Type: application/json" -H "X-Vault-Token: $token" "$@"
}


function kube::gen_cert() {
    token=$(kube::curl -X POST -d "{\"password\": \"kube\"}" https://127.0.0.1:8200/v1/auth/userpass/login/$2 |  jq -r ."auth.client_token")
    CERT=$(kube::curlt -X POST -d @/etc/vault/config/"$1".json https://127.0.0.1:8200/v1/kube/issue/"$2")
    echo "$CERT" | jq -r ."data.certificate" | sed 's/\\n/\n\r/g' >  /etc/kubernetes/ssl/"$3".pem
    echo "$CERT" | jq -r ."data.private_key" | sed 's/\\n/\n\r/g' >  /etc/kubernetes/ssl/"$3"-key.pem
    echo "$CERT" | jq -r ."data.serial_number" | sed 's/\\n/\n\r/g' >  /etc/kubernetes/ssl/sn-"$3".pem
    echo "$CERT" | jq -r ."data.issuing_ca" | sed 's/\\n/\n\r/g' >  /etc/kubernetes/ssl/ca-"$3".pem
}

function kube::generate_needed_certificates() {
    echo "Quering required ssl certificates for kubernetes"
    tar -xf certs/vault.tar -C /tmp
    cp certs/ca.pem /etc/kubernetes/ssl/
    cp certs/ca-key.pem /etc/kubernetes/ssl/
    envsubst < vault/issueCertNode.json > /etc/vault/config/issueCertNode.json
    token=$(kube::curl -X POST -d "{\"password\": \"etcd\"}" https://127.0.0.1:8200/v1/auth/userpass/login/etcd |  jq -r ."auth.client_token")
    CERT=$(kube::curlt -X POST -d @/etc/vault/config/issueCertNode.json https://127.0.0.1:8200/v1/etcd/issue/etcd)
    echo "$CERT" | jq -r ."data.certificate" | sed 's/\\n/\n\r/g' >  /etc/ssl/etcd/ssl/etcd.pem
    echo "$CERT" | jq -r ."data.private_key" | sed 's/\\n/\n\r/g' >  /etc/ssl/etcd/ssl/etcd-key.pem
    echo "$CERT" | jq -r ."data.serial_number" | sed 's/\\n/\n\r/g' >  /etc/ssl/etcd/ssl/sn-etcd.pem
    echo "$CERT" | jq -r ."data.issuing_ca" | sed 's/\\n/\n\r/g' >  /etc/ssl/etcd/ssl/ca.pem
    chmod 0640 /etc/ssl/etcd/ssl/etcd.pem
    chown kube:kube-cert /etc/ssl/etcd/ssl/*etcd*
    envsubst < vault/genCertKubeNodeMaster.json > /etc/vault/config/genCertKubeNodeMaster.json
    kube::gen_cert genCertKubeNodeMaster kube-node kube-node
    cp vault/genCertKubeProxyMaster.json /etc/vault/config
    kube::gen_cert genCertKubeProxyMaster kube-proxy kube-proxy
    if [ "$1" == 'master' ]
    then
        cp vault/genCertKubeAdmin.json /etc/vault/config/
        kube::gen_cert genCertKubeAdmin kube-master admin
        envsubst < vault/genCertKubeMaster.json > /etc/vault/config/genCertKubeMaster.json
        kube::gen_cert genCertKubeMaster kube-master apiserver
        kube::gen_cert genCertKubeMaster kube-master kube-scheduler
        kube::gen_cert genCertKubeMaster kube-master kube-controller-manager
    fi
    chmod 0640 /etc/kubernetes/ssl/*
    chown kube:kube-cert /etc/kubernetes/ssl/*
    cp /etc/kubernetes/ssl/ca.pem /etc/ssl/certs/kube-ca.pem
    update-ca-certificates > /dev/null
    rm -rf /tmp/home
}

function kube::configure_kube-proxy() {
    echo "Configuring kube-proxy"
    cp k8sConfig/kube-proxy-kubeconfig.yaml /etc/kubernetes/
    envsubst < k8sManifest/kube-proxy.manifest > /etc/kubernetes/manifests/kube-proxy.manifest
    sysctl -w net.ipv4.ip_local_reserved_ports="30000-32767" > /dev/null 2>&1
}

function kube::configure_kube-scheduler() {
    echo "Configuring kube-scheduler"
    cp k8sConfig/kube-scheduler-kubeconfig.yaml /etc/kubernetes/
    envsubst <  k8sManifest/kube-scheduler.manifest > /etc/kubernetes/manifests/kube-scheduler.manifest
}

function kube::configure_kube-controller-manager() {
    echo "Configuring kube-contoller-manaer"
    cp k8sConfig/kube-controller-manager-kubeconfig.yaml /etc/kubernetes/
    envsubst <  k8sManifest/kube-controller-manager.manifest > /etc/kubernetes/manifests/kube-controller-manager.manifest
}

function kube::configure_kube-apiserver() {
    echo "Configuring apiserver"
    envsubst < k8sManifest/kube-apiserver.manifest > /etc/kubernetes/manifests/kube-apiserver.manifest
}

function kube::configure_kubelet() {
    echo "Configuring kubelet"
    if [ "$1" == 'master' ]
    then
        envsubst < kubelet/kubelet-master.env > /etc/kubernetes/kubelet.env
    elif [ "$1" == 'ingress' ]
    then
        envsubst < kubelet/kubelet-ingress.env > /etc/kubernetes/kubelet.env
    else
        envsubst < kubelet/kubelet-worker.env > /etc/kubernetes/kubelet.env
    fi
    cp kubelet/kubelet.service /etc/systemd/system/kubelet.service
    cp kubelet/kubelet-kubeconfig.yaml /etc/kubernetes/kubelet-kubeconfig.yaml
    systemctl daemon-reload
    envsubst < kubelet/kubelet-container.sh > /opt/bin/kubelet
    chmod +x /opt/bin/kubelet
}

function kube::configure_kubernetes_users() {
    echo "Configuring kubernetes users"
    cp k8sConfig/known_users.csv /etc/kubernetes/users/
}

function kube::configure_kubectl() {
    echo "Configuring kubectl"
    docker run --rm -v /opt/bin:/systembindir quay.io/coreos/hyperkube:v1.9.2_coreos.0 /bin/cp /hyperkube /systembindir/kubectl
    envsubst < k8sConfig/admin.conf > /etc/kubernetes/admin.conf
    chmod 640 /etc/kubernetes/admin.conf
    cp /etc/kubernetes/admin.conf /root/.kube/config
    chmod 700 /root/.kube/config
}

function kube::start_kubelet() {
    echo "Starting kubelet ..."
    systemctl enable kubelet.service > /dev/null 2>&1
    systemctl daemon-reload
    systemctl start kubelet.service
    sleep 5
    if [ "$1" == 'master' ]
    then
        curl --silent --retry-connrefused --connect-timeout 5 --retry 10 --retry-delay 0 --retry-max-time 40 http://127.0.0.1:8080/healthz
    fi
}

function kube::configure_network_plugin() {
    echo "Configure Network plugin"
    if [ "$1" == 'master' ]
    then
        ETCD_CA=$(base64 /etc/ssl/etcd/ssl/ca.pem | tr -d '\n')
        export ETCD_CA
        ETCD_CERT=$(base64 /etc/ssl/etcd/ssl/etcd.pem | tr -d '\n')
        export ETCD_CERT
        ETCD_KEY=$(base64 /etc/ssl/etcd/ssl/etcd-key.pem | tr -d '\n')
        export ETCD_KEY
        envsubst < calico/deploy-calico.yml | kubectl apply -f -
    fi
    while [ ! -f /etc/cni/net.d/calico-kubeconfig ]; do sleep 2; done
    cp /etc/kubernetes/kubelet-kubeconfig.yaml /etc/cni/net.d/calico-kubeconfig
}

function kube::configure_coreDNS() {
    echo "Configure coreDNS"
    envsubst < coreDNS/deploy-coreDNS.yml | kubectl apply -f -
}

function kube::configure_helm() {
    echo "Configure helm"
    cp helm/helm /opt/bin
    chmod +x /opt/bin/helm
    cp helm/helm-sa.yml /etc/kubernetes/manifests/
    /opt/bin/kubectl apply -f /etc/kubernetes/manifests/helm-sa.yml
    /opt/bin/helm init --service-account tiller --upgrade
}

function kube::configure_ingress() {
    cp nginx-ingress/values.yml /root/.helm/nginx_ingress_values.yaml
    helm install stable/nginx-ingress --name nginx-ingress -f /root/.helm/nginx_ingress_values.yaml --namespace nginx-ingress
}

function kube::install_dashboard() {
    echo "Installing dashboard"
    cp kuberntes_apps/expose_apps.yaml /etc/kubernetes/manifests
    helm install stable/kubernetes-dashboard --name kube-dashboard --set rbac.create=yes --namespace kube-system
    kubectl apply -f /etc/kubernetes/manifests/expose_dashboard.yaml
    echo "Dashboard can be accessed through http://<ingressIP>/ui/"
}
function kube::install_prometheus_operator() {
    echo "Installing prometheus operator"
    helm repo add coreos https://s3-eu-west-1.amazonaws.com/coreos-charts/stable/
    helm install coreos/prometheus-operator --name prometheus-operator --set global.rbacEnable=true --namespace monitoring
    helm install coreos/kube-prometheus --name kube-prometheus --set global.rbacEnable=true --namespace monitoring
    echo "Need to work on exposing prometheus through the ingress"
}
