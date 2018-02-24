#!/bin/bash

source linkerd/linkerd-vars.sh
source k8sConfig/k8sConfig-vars.sh
source k8sConfig/functions.sh
source linkerd/functions.sh

linkerd::create_needed_folders
linkerd::configure_linkerd-tcp master
linkerd::start_linkerd-tcp

kube::create_needed_folders master
kube::generate_needed_certificates master
kube::configure_kube-proxy
kube::configure_kube-scheduler
kube::configure_kube-controller-manager
kube::configure_kube-apiserver
kube::configure_kubelet master
kube::configure_kubernetes_users
kube::configure_kubectl
kube::start_kubelet master

kube::configure_network_plugin master
kube::configure_coreDNS
kube::configure_helm
