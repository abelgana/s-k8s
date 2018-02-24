#!/bin/bash

source linkerd/linkerd-vars.sh
source k8sConfig/k8sConfig-vars.sh
source k8sConfig/functions.sh
source linkerd/functions.sh

linkerd::create_needed_folders
linkerd::configure_linkerd-tcp ingress
linkerd::start_linkerd-tcp

kube::create_needed_folders ingress
kube::generate_needed_certificates ingress
kube::configure_kube-proxy
kube::configure_kubelet ingress
kube::start_kubelet ingress

kube::configure_network_plugin ingress
