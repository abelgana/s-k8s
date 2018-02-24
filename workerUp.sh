#!/bin/bash

source linkerd/linkerd-vars.sh
source k8sConfig/k8sConfig-vars.sh
source k8sConfig/functions.sh
source linkerd/functions.sh

linkerd::create_needed_folders
linkerd::configure_linkerd-tcp worker
linkerd::start_linkerd-tcp

kube::create_needed_folders worker
kube::generate_needed_certificates worker
kube::configure_kube-proxy
kube::configure_kubelet worker
kube::start_kubelet worker

kube::configure_network_plugin worker
